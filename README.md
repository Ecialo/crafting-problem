# Crafting problem

## How to run

```rebar3 shell```
The server will be run on port `8080`
The routes are:
* `/api/job/sort-tasks` for sorting with JSON response
* `/api/job/compile-command` for aquiring of the whole bash script

For simplicity you also can use the bash script in the other terminal:

* To sort job tasks and get a JSON response: `./send_to_sort.sh sort`
* To acquire the fully compiled script: `./send_to_sort.sh compile`
* To use a custom payload: `./send_to_sort.sh compile ./path/to/payload.json`

## Some decisions

* I decided to offload task‑sorting work to a GenServer. This allows the meaningful work to scale separately from request processing. Under load it should be able to handle at least some jobs. On the other hand, one large job may paralyze everything. In that case the server should be refactored into a pool‑like design.

* I decided not to construct the resulting script as the toposort goes. It's definitely possible and might (or might not) gain something by avoiding an additional traversal of the result structure, but it would raise code complexity, and I see no reason to do it for this task.

* I decided to return a `400` status code when a cycle is detected in the tasks. It's bad data, but not broken, and I think the request should be rejected. I also return `400` for tasks that depend on nonexistent tasks.

## List of examples

* `example.json` -- provided example
* `cyclic_example.json` -- example with cyclic dependicies
* `nonexistence_example.json` -- example with nonexistent dependency