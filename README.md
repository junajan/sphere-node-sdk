![SPHERE.IO icon](https://admin.sphere.io/assets/images/sphere_logo_rgb_long.png)

# Node.js Client

[![Build Status](https://secure.travis-ci.org/sphereio/sphere-node-client.png?branch=master)](http://travis-ci.org/sphereio/sphere-node-client) [![NPM version](https://badge.fury.io/js/sphere-node-client.png)](http://badge.fury.io/js/sphere-node-client) [![Coverage Status](https://coveralls.io/repos/sphereio/sphere-node-client/badge.png?branch=master)](https://coveralls.io/r/sphereio/sphere-node-client?branch=master) [![Dependency Status](https://david-dm.org/sphereio/sphere-node-client.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-client) [![devDependency Status](https://david-dm.org/sphereio/sphere-node-client/dev-status.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-client#info=devDependencies)

[SPHERE.IO](http://sphere.io/) is the first **Platform-as-a-Service** solution for eCommerce.

This module is a standalone Node.js client for accessing the Sphere HTTP APIs.

## Table of Contents
* [Getting Started](#getting-started)
* [Documentation](#documentation)
  * [Services](#services)
  * [Types of requests](#types-of-requests)
    * [Query request](#query-request)
      * [Query all (limit 0)](#query-all-limit0)
      * [Query for modifications](#query-for-modifications)
      * [Staged products](#staged-products)
    * [Create resource](#create-resource)
      * [Import orders](#import-orders)
    * [Update resource](#update-resource)
    * [Delete resource](#delete-resource)
  * [Error handling](#error-handling)
  * [Batch processing](#batch-processing)
* [Examples](#examples)
* [Releasing](#releasing)
* [License](#license)


## Getting Started
Install the module with `npm install sphere-node-client`

```coffeescript
SphereClient = require 'sphere-node-client'
```

## Documentation
To start using the Sphere client you need to create an instance of the `SphereClient` by passing the credentials (and other options) in order to connect with the HTTP APIs. Project credentials can be found in the SPHERE.IO [Merchant Center](https://admin.sphere.io/) under `Developers > API clients` section.

> For a list of options to pass to the client, see [`sphere-node-connect`](https://github.com/emmenko/sphere-node-connect#documentation).

```coffeescript
client = new SphereClient
  config:
    client_id: "CLIENT_ID_HERE"
    client_secret: "CLIENT_SECRET_HERE"
    project_key: "PROJECT_KEY_HERE"
```

### Services
The `SphereClient` provides a set of Services to connect with the related API endpoints. Currently following services are supported:

- `carts`
- `categories`
- `channels`
- `comments`
- `customObjects`
- `customerGroups`
- `customers`
- `inventoryEntries`
- `messages`
- `orders`
- `productProjections`
- `productTypes`
- `products`
- `reviews`
- `shippingMethods`
- `states`
- `taxCategories`
- `zones`

### Types of requests
Requests to the HTTP API are obviously asynchronous and they all return a [`Q` promise](https://github.com/kriskowal/q).

```coffeescript
client = new SphereClient {...}

client.products.fetch()
.then (result) ->
  # a JSON object containing either a result or a SPHERE.IO HTTP error
.fail (error) ->
  # either the request failed or was rejected (the response returned an error)
```

Current methods using promises are:

- `fetch` HTTP `GET` request
- `save` HTTP `POST` request
- `update` HTTP `POST` request (_alias for `save`_)
- `delete` HTTP `DELETE` request


#### Query request
All resource endpoints support queries, returning a list of results of type [PagedQueryResponse](http://commercetools.de/dev/http-api.html#paged-query-response).

> Fetching and endpoint without specifying and `ID` returns a `PagedQueryResponse`

A query request can be configured with following query parameters:

- `where` ([Predicate](http://commercetools.de/dev/http-api.html#predicates))
- `sort` ([Sort](http://commercetools.de/dev/http-api.html#sorting))
- `limit` (Number)
- `offset` (Number)

The `SphereClient` helps you build those requests with following methods:

- `where(predicate)` defines a URI encoded predicate from the given string (can be set multiple times)
- `whereOperator(operator)` defines the logical operator to combine multiple where parameters
- `last(period)` defines a [time period](#query-for-modifications) for a query on the `lastModifiedAt` attribute of all resources
- `sort(path, ascending)` defines how the query result should be sorted - true (default) defines ascending where as false indicates descascending
- `page(n)` defines the page number to be requested from the complete query result (default is `1`). **If < 1 it throws an error**
- `perPage(n)` defines the number of results to return from a query (default is `100`). If set to `0` all results are returned (_more [info](https://github.com/emmenko/sphere-node-connect#paged-requests)_). **If < 0 it throws an error**

> All these methods are chainable

```coffeescript
# example

client = new SphereClient {...}
client.products
.where('name(en="Foo")')
.where('id="1234567890"')
.whereOperator('or')
.page(3)
.perPage(25)
.sort('name', false)
.fetch()

# HTTP request
# /{project_key}/products?where=name(en%3D%22Foo%22)%20or%20id%3D%221234567890%22&limit=25&offset=50&sort=name%20desc
```

##### Query all (limit=0)
If you want to retrieve all results of a resource, you can set the `perPage` param to `0`.
In that case the results are recursively requested in chunks and returned all together once completed.

```coffeescript
client = new SphereClient {...}
client.perPage(0).fetch()
.then (result) -> # `results` is still a `PagedQueryResponse` containing all results of the query
.fail (error) ->
```

Since the request is executed recursively until all results are returned, you can **subscribe to the progress notification** in order to follow the progress

```coffeescript
client = new SphereClient {...}
client.perPage(0).fetch()
.then (result) ->
.progress (progress) ->
  # progress is an object containing the current progress percentage
  # and the value of the current results (array)
  # e.g. {percentage: 20, value: [r1, r2, r3, ...]}
  console.log "#{progress.percentage}% completed..."
.fail (error) ->
```

More info [here](https://github.com/emmenko/sphere-node-connect#paged-requests).

##### Query for modifications
If you want to retrieve only those resources that changed over a given time, you can chain the `last` functions,
that builds a query for you based on the `lastModifiedAt` attribute.

The format of the `period` parameter is a number followed by one of the following characters:
- `s` for seconds - eg. `30s`
- `m` for minutes - eg. `15m`
- `h` for hours - eg. `6h`
- `d` for days - eg. `7d`

```coffeescript
# example

client = new SphereClient {...}
client.orders.last('2h').fetch()
```

> Please be aware that `last` is just another `where` clause and thus depends on the `operator` you choose - default is `and`.

##### Staged products
The `ProductProjectionService` returns a representation of the products called [ProductProjection](http://commercetools.de/dev/http-api-projects-products.html#product-projection) which corresponds basically to a **catalog** or **staged** representation of a product. When using this service you can specify which projection of the product you would like to have by defining a `staged` parameter (default is `true`).

```coffeescript
# example

client = new SphereClient {...}
client.productProjections
.staged()
.fetch()

# HTTP request
# /{project_key}/products-projections?staged=true
```

#### Create resource
All endpoints allow a resource to be created by posting a JSON `Representation` of the selected resource as a body payload.

```coffeescript
product =
  name:
    en: 'Foo'
  slug:
    en: 'foo'
  ...

client.products.save(product)
.then (result) ->
  # a JSON object containing either a result or a SPHERE.IO HTTP error
.fail (error) ->
  # either the request failed or was rejected (the response returned an error)
```

##### Import orders
The `OrderService` exposes a specific function to [import orders](http://commercetools.de/dev/http-api-projects-orders-import.html).
Use it as you would use the `save` function, just internally the correct API endpoint is set.

```coffeescript
client.orders.import(order)
```

#### Update resource
Updates are just a POST request to the endpoint specified by an `ID`, provided with a body payload of [Update Actions](http://commercetools.de/dev/http-api.html#partial-updates).

> The `update` method is just an alias for `save`, given the resource `ID`. If no `ID` is provided, it will try to send the request to the base resource endpoint, expecting a new resource to be created, so make sure that the **body** has the correct format (create or update).

```coffeescript
# new product
product =
  name:
    en: 'Foo'
  slug:
    en: 'foo'
  ...

# update action for product name
update =
  version: 1,
  actions: [
    {
      action: 'changeName'
      name:
        en: 'Foo'
    }
  ]

# this will try to create a new product with the correct body
# -> OK
client.products.save(product)
client.products.update(product)

# this will try to create a new product with a wrong body
# -> FAILS
client.products.save(update)
client.products.update(update)

# this will try to update a product with a correct body
# -> OK
client.products.byId('123-abc').save(update)
client.products.byId('123-abc').update(update)
```

#### Delete resource
Some endpoints (for now) allow a resource to be deleted by providing the `version` of current resource as a query parameter.

```coffeescript
# assume that we have a product
client.products.byId('123-abc').fetch()
.then (product) ->
  client.products.byId('123-abc').delete(product.version)
.then (result) ->
  # a JSON object containing either a result or a SPHERE.IO HTTP error
.fail (error) ->
  # either the request failed or was rejected (the response returned an error)
```

### Error handling
As the HTTP API [handles errors](https://github.com/emmenko/sphere-node-connect#error-handling) _gracefully_ by providing a JSON body with error codes and messages, the `SphereClient` handles that by providing an intuitive way of dealing with responses.

Since a Promise can be either resolved or rejected, the result is determined by valuating the `statusCode` of the response:
- `resolved` everything with a successful HTTP status code
- `rejected` everything else

**A rejected promise always contains a JSON object as following**

```javascript
// example
{
  "statusCode": 400,
  "message": "An error message",
  ... // other fields according to the SPHERE.IO API errors
}
```

The client application can then easily decide what to do

```coffeescript
client.products.save({})
.then (result) ->
  # we know the request was successful (e.g.: 2xx) and `result` is a JSON of a resource representation
.fail (error) ->
  # something went wrong, either an unexpected error or a HTTP API error response
  # here we can check the `statusCode` to differentiate the error
  switch error.statusCode
    when 400 then # do something
    when 500 then # do something
    ...
    else # do something else
```

### Batch processing
Batch processing allows a list of requests to be executed in chunks, to avoid too many parallel requests.
There are some [**mixins**](https://github.com/sphereio/sphere-node-utils#mixins) available in the [`sphere-node-utils`](https://github.com/sphereio/sphere-node-utils) repository.


## Examples
_(Coming soon)_

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).
More info [here](CONTRIBUTING.md)

## Releasing
Releasing a new version is completely automated using the Grunt task `grunt release`.

```javascript
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

## License
Copyright (c) 2014 SPHERE.IO
Licensed under the [MIT license](LICENSE-MIT).
