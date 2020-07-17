from dataclasses import dataclass
from datetime import datetime
from influxdb import InfluxDBClient
from json import JSONDecodeError
from typing import Iterator
from urllib3.exceptions import MaxRetryError
import click
import os
import logging
import re
import requests
import requests_html
import retrying
import six
import time


logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())


def retry_cases(exception):
    return isinstance(exception, MaxRetryError) or \
        isinstance(exception, JSONDecodeError) or \
        isinstance(exception, requests.ConnectionError)

class Item:
    pass

class Category:
    pass

class PriceMeasurement:
    pass

@dataclass
class Item:
    id: int
    name: str
    members: bool
    category: Category

    @retrying.retry(retry_on_exception=retry_cases, wait_random_min=1000, wait_random_max=3000)
    def __fetch_price_history(self):
        response = requests.get("https://services.runescape.com/m=itemdb_rs/api/graph/{}.json".format(
            self.id
        ))

        if response.ok:
            return response.json()
        else:
            return dict(daily={})

    def get_price_history(self):
        history = self.__fetch_price_history()
        for k, v in history["daily"].items():
            yield PriceMeasurement(
                self,
                self.category,
                PriceMeasurement.parse(v),
                datetime.utcfromtimestamp(int(k) / 1000)
            )


@dataclass
class Category:
    id: int
    name: str

    @retrying.retry(retry_on_exception=retry_cases)
    def __fetch_breakdown(self):
        response = requests.get("https://services.runescape.com/m=itemdb_rs/api/catalogue/category.json?category={}".format(
            self.id))

        if response.ok:
            return response.json()
        else:
            return dict(alpha=[])

    @retrying.retry(retry_on_exception=retry_cases, wait_random_min=1000, wait_random_max=3000)
    def __fetch_page(self, letter, page):
        response = requests.get("https://services.runescape.com/m=itemdb_rs/api/catalogue/items.json?category={}&alpha={}&page={}".format(
            self.id, letter, page))

        if response.ok:
            return response.json()
        else:
            return dict(items=[])

    def get_item_count(self) -> int:
        breakdown = self.__fetch_breakdown()
        total = sum(map(lambda x: x["items"], breakdown["alpha"]))

        return total

    def get_items(self) -> Iterator[Item]:
        for measurement in self.get_item_prices():
            yield measurement.item

    def get_item_prices(self) -> Iterator[PriceMeasurement]:
        breakdown = self.__fetch_breakdown()
        total = sum(map(lambda x: x["items"], breakdown["alpha"]))

        for start_letter in breakdown["alpha"]:
            count = 0
            page = 1
            empty_page = False

            while count < start_letter["items"] and not empty_page:
                if start_letter["letter"] == "#":
                    items = self.__fetch_page("%23", page)
                else:
                    items = self.__fetch_page(start_letter["letter"], page)

                if items["items"]:
                    for i in items["items"]:
                        item = Item(i["id"], i["name"], i["members"] == "true", self)
                        yield PriceMeasurement(
                            item,
                            self,
                            PriceMeasurement.parse(i["current"]["price"])
                        )

                        count += 1
                else:
                    empty_page = True

                page += 1


@dataclass
class PriceMeasurement:
    item: Item
    category: Category
    price: int
    dt: datetime = None

    def date(self, dt : datetime):
        self.dt = dt

    @classmethod
    def parse(cls, price):
        if isinstance(price, six.integer_types):
            return price
        else:
            price = price.strip()
            m = re.search("^(\d+(?:\.\d+)?)([kmb])$", price)

            if m:
                base = float(m.group(1))
                modifier = {
                    "k": 1000,
                    "m": 1000000,
                    "b": 1000000000
                }[m.group(2)]

                return base * modifier
            else:
                return int(price.replace(",", ""))

    def to_dict(self) -> dict:
        return {
            "measurement": "price",
            "tags": {
                "category_id": self.category.id,
                "category": self.category.name,
                "item_id": self.item.id,
                "item": self.item.name,
                "members": self.item.members
            },
            "time": self.dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "fields": {
                "value": self.price
            }
        }


def categories_generator() -> Iterator[Category]:
    """
    Extract item categories from the RS website.
    """
    session = requests_html.HTMLSession()
    response = session.get("https://secure.runescape.com/m=itemdb_rs/catalogue")

    for i in response.html.find('.categories a'):
        name = i.text
        category_id = int(i.attrs["href"].split("=")[-1])

        yield Category(category_id, name)


def write(measurements, client):
    client.write_points(map(lambda x: x.to_dict(), measurements))


@click.group()
@click.option("--database", "-d", help="Influx database")
@click.pass_context
def cli(ctx, database):
    ctx.ensure_object(dict)
    ctx.obj["DATABASE"] = database

@cli.command()
@click.pass_context
def poll(ctx):
    client = InfluxDBClient("localhost", 8086, "root", "root", ctx.obj["DATABASE"])
    timestamp = datetime.now()

    for category in categories_generator():
        measurements = []

        logger.info("Processing category %s (%s): %s items",
            category.id, category.name, category.get_item_count())
        for price in category.get_item_prices():
            price.date(timestamp)
            logger.debug(price.to_dict())

            measurements.append(price)

        write(measurements, client)


@cli.command()
@click.pass_context
def load(ctx):
    client = InfluxDBClient("localhost", 8086, "root", "root", ctx.obj["DATABASE"])

    for category in categories_generator():
        if category.id in (1, 41, 2, 3, 4, 5, 6, 7, 8, 9, 10, 40):
            continue

        measurements = []

        logger.info("Processing category %s (%s): %s items",
            category.id, category.name, category.get_item_count())
        for item in category.get_items():
            measurements.extend(item.get_price_history())

        write(measurements, client)


if __name__ == '__main__':
    cli()