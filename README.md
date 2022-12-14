# prql-query (pq)

[![license](http://img.shields.io/badge/license-Apache%20v2-blue.svg)](https://raw.githubusercontent.com/prql/prql-query/main/LICENSE-APACHE)
[![license](http://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/prql/prql-query/main/LICENSE-MIT)

## Query and transform data with PRQL

[PRQL](https://prql-lang.org/) is a modern language for transforming data
— a simple, powerful, pipelined SQL replacement

**`pq`** allows you to use [PRQL](https://prql-lang.org/) to easily query and
transform your data. It is powered by  [Apache Arrow
DataFusion](https://arrow.apache.org/datafusion/) and
[DuckDB](https://duckdb.org/) and is written in Rust (so it's "blazingly fast"
™)!

Licensed under
[Apache](https://raw.githubusercontent.com/prql/prql-query/main/LICENSE-APACHE) or
[MIT](https://raw.githubusercontent.com/prql/prql-query/main/LICENSE-MIT).

## Examples

    $ pq --from albums.csv "take 5"
    +----------+---------------------------------------+-----------+
    | album_id | title                                 | artist_id |
    +----------+---------------------------------------+-----------+
    | 1        | For Those About To Rock We Salute You | 1         |
    | 2        | Balls to the Wall                     | 2         |
    | 3        | Restless and Wild                     | 2         |
    | 4        | Let There Be Rock                     | 1         |
    | 5        | Big Ones                              | 3         |
    +----------+---------------------------------------+-----------+

    $ pq -f i=invoices.csv -f c=customers.csv --to invoices_with_names.parquet \
        'from i | join c [customer_id] | derive [name = f"{first_name} {last_name}"]'

    $ pq -f invoices_with_names.parquet --format json \
        'group name (aggregate [spend = sum total]) | sort [-spend] | take 10'

    {"name":"Helena Holý","spend":49.620000000000005}
    {"name":"Richard Cunningham","spend":47.620000000000005}
    {"name":"Luis Rojas","spend":46.62}
    {"name":"Hugh O'Reilly","spend":45.62}
    {"name":"Ladislav Kovács","spend":45.62}
    {"name":"Julia Barnett","spend":43.620000000000005}
    {"name":"Fynn Zimmermann","spend":43.62}
    {"name":"Frank Ralston","spend":43.62}
    {"name":"Astrid Gruber","spend":42.62}
    {"name":"Victor Stevens","spend":42.62}

## Installation

### Download a binary from Github Releases

Binaries are built for Windows, macOS and Linux for every release and can be
dowloaded from [Releases](https://github.com/prql/prql-query/releases/)
([latest](https://github.com/prql/prql-query/releases/latest)).

For example on linux you could download and install `pq` with:

    VERSION=v0.0.14 wget https://github.com/prql/prql-query/releases/download/$VERSION/pq-x86_64-unknown-linux-gnu.tar.gz && \
        tar xvzf pq-x86_64-unknown-linux-gnu.tar.gz --directory ~/.local/bin && \
        rm pq-x86_64-unknown-linux-gnu.tar.gz

### Run as a container image (Docker)

    docker pull ghcr.io/prql/prql-query
    alias pq="docker run --rm -it -v $(pwd):/data -e HOME=/tmp -u $(id -u):$(id -g) ghcr.io/prql/prql-query"
    pq --help

Please note that if you want to build the container image yourself with Docker then you will need
at least 10 GB of memory available to the Docker VM, otherwise libduckdb-sys will fail to compile.

### Via Homebrew

    brew tap prql/homebrew-prql-query
    brew install prql-query

### Via Rust toolchain (Cargo)

    cargo install prql-query

## Usage

### Generating SQL

At its simplest `pq` takes PRQL queries and transpiles them to SQL queries:

    $ pq "from a | select b"
    SELECT
      b
    FROM
      a

Input can also come from stdin:

    $ cat examples/queries/invoice_totals.prql | pq

For convenience, queries ending in ".prql" are assumed to be paths to PRQL query files and will be read in so this produces the same as above:

    $ pq examples/queries/invoice_totals.prql

Both of these produce the output:

    SELECT
      STRFTIME('%Y-%m', i.invoice_date) AS month,
      STRFTIME('%Y-%m-%d', i.invoice_date) AS day,
      COUNT(DISTINCT i.invoice_id) AS num_orders,
      SUM(ii.quantity) AS num_tracks,
      SUM(ii.unit_price * ii.quantity) AS total_price,
      SUM(SUM(ii.quantity)) OVER (
        PARTITION BY STRFTIME('%Y-%m', i.invoice_date)
        ORDER BY
          STRFTIME('%Y-%m-%d', i.invoice_date) ROWS BETWEEN UNBOUNDED PRECEDING
          AND CURRENT ROW
      ) AS running_total_num_tracks,
      LAG(SUM(ii.quantity), 7) OVER (
        ORDER BY
          STRFTIME('%Y-%m-%d', i.invoice_date) ROWS BETWEEN UNBOUNDED PRECEDING
          AND UNBOUNDED FOLLOWING
      ) AS num_tracks_last_week
    FROM
      invoices AS i
      JOIN invoice_items AS ii USING(invoice_id)
    GROUP BY
      STRFTIME('%Y-%m', i.invoice_date),
      STRFTIME('%Y-%m-%d', i.invoice_date)
    ORDER BY
      day

### Querying data from a database (using CLI clients)

With the functionality described above, you should be able to query your favourite SQL RDBMS using your favourite CLI client and `pq`. For example with the `psql` client for PostgreSQL:

    $ pq "from my_table | take 5" | psql postgresql://username:password@host:port/database

Or using the `mysql` client for MySQL with a PRQL query stored in a file:

    $ pq my_query.prql | mysql -h myhost -d mydb -u myuser -p mypassword

Similarly for MS SQL Server and other databases.

### Querying data in files (csv, parquet, json)

For querying and transforming data stored on the local filesystem, `pq` comes in with a number of built-in backend query processing engines. The default backend is [Apache Arrow DataFusion](https://arrow.apache.org/datafusion/). However [DuckDB](https://duckdb.org/) and [SQLite](https://www.sqlite.org/) (planned) are also supported.

When `--from` arguments are supplied which specify data files, the PRQL query will be applied to those files. The files can be referenced in the queries by the filenames without the extensions, e.g. customers.csv can be referenced as the table `customers`. For convenience, unless a query already begins with a `from ...` step, a `from <table>` pipeline step will automatically be inserted at the beginning of the query referring to the last `--from` argument encountered, i.e. the following two are equivalent:

    $ pq --from examples/data/chinook/csv/invoices.csv "from invoices|take 5"
    $ pq --from examples/data/chinook/csv/invoices.csv "take 5"
    +------------+-------------+-------------------------------+-------------------------+--------------+---------------+-----------------+---------------------+-------+
    | invoice_id | customer_id | invoice_date                  | billing_address         | billing_city | billing_state | billing_country | billing_postal_code | total |
    +------------+-------------+-------------------------------+-------------------------+--------------+---------------+-----------------+---------------------+-------+
    | 1          | 2           | 2009-01-01T00:00:00.000000000 | Theodor-Heuss-Straße 34 | Stuttgart    |               | Germany         | 70174               | 1.98  |
    | 2          | 4           | 2009-01-02T00:00:00.000000000 | Ullevålsveien 14        | Oslo         |               | Norway          | 0171                | 3.96  |
    | 3          | 8           | 2009-01-03T00:00:00.000000000 | Grétrystraat 63         | Brussels     |               | Belgium         | 1000                | 5.94  |
    | 4          | 14          | 2009-01-06T00:00:00.000000000 | 8210 111 ST NW          | Edmonton     | AB            | Canada          | T6G 2C7             | 8.91  |
    | 5          | 23          | 2009-01-11T00:00:00.000000000 | 69 Salem Street         | Boston       | MA            | USA             | 2113                | 13.86 |
    +------------+-------------+-------------------------------+-------------------------+--------------+---------------+-----------------+---------------------+-------+

You can also assign an alias for source file with the following form `--from <alias>=<filepath>` and then refer to it by that alias in your queries. So the following is another equivalent form of the queries above:

    $ pq --from i=examples/data/chinook/csv/invoices.csv "from i|take 5"

This works with multiple files which means that the extended example above can be run as follows:

    $ pq -b duckdb -f examples/data/chinook/csv/invoices.csv -f examples/data/chinook/csv/invoice_items.csv examples/queries/invoice_totals.prql

### Transforming data with `pq` and writing the output to files

When a `--to` argument is supplied, the output will be written there in the appropriate file format instead of stdout (the "" query is equivalent to `select *` and is required because `select *` currently does not work):

    $ pq --from examples/data/chinook/csv/invoices.csv --to invoices.parquet ""

Currently csv, parquet and json file formats are supported for both readers and writers:

    $ cat examples/queries/customer_totals.prql
    group [customer_id] (
        aggregate [
            customer_total = sum total,
        ])
    $ pq -f invoices.parquet -t customer_totals.json examples/queries/customer_totals.prql
    $ pq -f customer_totals.json "sort [-customer_total] | take 10"
    +-------------+--------------------+
    | customer_id | customer_total     |
    +-------------+--------------------+
    | 6           | 49.620000000000005 |
    | 26          | 47.620000000000005 |
    | 57          | 46.62              |
    | 46          | 45.62              |
    | 45          | 45.62              |
    | 28          | 43.620000000000005 |
    | 37          | 43.62              |
    | 24          | 43.62              |
    | 7           | 42.62              |
    | 25          | 42.62              |
    +-------------+--------------------+

### Querying data in a DuckDB database

DuckDB is natively supported and can be queried by supplying a database URI
beginning with "duckdb://".

    $ pq --database duckdb://examples/chinook/duckdb/chinook.duckdb \
        'from albums | join artists [artist_id] | group name (aggregate [num_albums = count]) | sort [-num_albums] | take 10'

### Querying Sqlite databases

Sqlite is currently supported through the [sqlite_scanner](https://github.com/duckdblabs/sqlite_scanner)
DuckDB extension. In order to query a SQLite database, a database URI
beginning with "sqlite://" needs to be supplied.

    $ pq --database sqlite://examples/chinook/sqlite/chinook.sqlite \
        'from albums | take 10'

### Querying PostgreSQL databases

PostgreSQL is currently supported through the
[postgres-scanner](https://github.com/duckdblabs/postgres_scanner) DuckDB
extension. (See the [announcement blog post](https://duckdb.org/2022/09/30/postgres-scanner) 
for a good introduction.)

    $ pq -d postgresql://username:password@host:port/database \
        'from table | take 10'

One noteworthy limitation of this approach is that you can only query
tables in the postgres database and not views.

By default you will be connected to the "public" schema and can reference tables
there within your query. You can specify a different schema to connect to using
the "?currentSchema=schema" paramter. If you want to query tables from another schema
outside of that then you currently have to reference these through aliased
`--from` parameters like so:

    $ pq -d postgresql://username:password@host:port/database?currentSchema=schema \
        --from alias=other_schema.table 'from alias | take 10'

### Environment Variables

If you plan to work with the same database repeatedly, then specifying the
details each time quickly becomes tedious. `pq` allows you to supply all
command line arguments from environment variables with a `PQ_` prefix. So for
example the same query from above could be achieved with:

    $ export PQ_DATABASE="postgresql://username:password@host:port/database"
    $ pq --from alias=schema.table 'take 10'

### .env files

Environment variables can also be read from a `.env` files. Since you probably
don't want to expose your database credentials at the shell, it makes sense to
put these in a `.env` file. This also allows you to set up directories with
configuration for common environments together with common queries for that
environment, for example:

    $ echo 'PQ_DATABASE="postgresql://username:password@host:port/database"' > .env
    $ pq 'from my_schema.my_table | take 5'

Or say that you have a `status_query.prql` that you need to run for a number of environments with .env files set up in subdirectories:

    $ for e in prod uat dev; do cd $e && pq ../status_query.prql; done

## Roadmap

### 0.1.0

* Tests
* Publish to crates.io

### 0.2.0

* Support for object stores

### 0.3.0

* Support for other databases through `connectorx`
