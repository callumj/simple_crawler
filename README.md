# SimpleCrawler

This project is a simple crawling tool for recording a webpages association with assets and other pages.

## Overview

A `CrawlSession` is a object that represents a queue, results and a storage persistance layer. It provides the knowledge about what URLs are allowed to be crawled, where the results should be stored and where they should be written to.

A session operates around `GlobalQueue`, a queue of URIs that need to be processed by `ContentFetcher`s. After a fetch job is complete, it will then enqueue all links and stylesheets on the queue. This maintains a central repository of "jobs" that need to be completed.

A `ContentFetcher` will first download the target (unless the target is forbidden to be downloaded, as decided by its file extension) and then ask the scrapers for information about the downloaded page.

With this, the fetcher has now built up content information which it can then pass back to the session.

The session then adds this content to the `ResultsStore` and then enqueues the links and stylesheet assets.

## Data Collected

In the `ResultsStore` the following data is collected

* `contents` (map): A list of pages with the assets they depend on and the links to other webpages (internal or external)
* `local_stylesheets`: A list of the stylesheets and the assets they depend on
* `assets_usage`: A list of assets and the pages that utilise them
* `incoming_links`: A list of pages and the pages they are linked to

## Server mode

`SimpleCrawler` provides support for operating in a client server mode. One task is started in server mode which is responsible for managing the session (queue and results store) and other clients interact with this session over the network. Client server mode is an excellent way to overcome MRI's single CPU limitations or rope additional boxes into the crawling operation.

The `SimpleCrawler::Client::CrawlSession` implements a proxy verison of `CrawlSession` which uses `Connection` to send messages to the server over a TCP socket.

**Be aware that communication between clients and server is achieved by marshalling Ruby objects which opens up the system to remote code execution vulnerabilities if the port is exposed. I recommend only operating client server on the same box or within the same data centre.**


## CLI usage

This tool is consists of two `rake` tasks

* `single_run`: A single thread crawl that processes the queue one by one
* `run`: A multi worker crawl that spins up a set amount of workers that are always trying to empty the queue
* `server`: A server instance that allows workers (via `run`) to connect to it and work together to deplete the queue. This task will be responsible for storing the data and producing the final output.

Both tasks support the following environment variables

* `URL`: The initial URL to crawl (not available when the task is a client)
* `OUTPUT`: The directory that the storage adapter will write to
* `LOG`: The file to write the log to, use "NONE" to disable logging

The `run` task also supports the following

* `MAX_WORKERS`: The max number of workers that can scale up. Default is `50`.
* `SERVER`: An address like 127.0.0.1:9018 to connect to and operate in client mode. Note this disables the `URL` environment variable.

The `server` task also supports the following

* `LISTEN`: An address to listen to in the form of 127.0.0.1:9018 or :9018

## Getting started

* Install the gems described by the gemfile: `bundle install`
* Invoke the task: `bundle exec rake TASK_NAME`

## Workers

A `Worker` is a object that takes a session, pops off the next URI, starts a fetcher and attempts to add the content info back.