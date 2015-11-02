/**
 * Utils `verbs` module.
 * @module utils/verbs
 */
import buildAbsoluteUrl from './build-absolute-url'
import buildQueryString from './build-query-string'
import { setDefaultParams } from './default-params'

/**
 * Fetch a resource defined by the `service` with all related query parameters.
 *
 * @return {Promise} A `task` promise that will eventually be resolved.
 *
 * @example
 *
 * ```js
 * service = client.productProjections
 * service.where('name(en = "Foo")').sort('createdAt desc').fetch()
 * .then()
 * .catch()
 * ```
 */
export function fetch () {
  const endpointWithId = this.params.id ?
    `${this.baseEndpoint}/${this.params.id}` : this.baseEndpoint
  const queryParams =
    this.params.customQuery || buildQueryString(this.params)
  const endpoint = endpointWithId + (queryParams ? `?${queryParams}` : '')
  const url = buildAbsoluteUrl(this.options, endpoint)

  setDefaultParams.call(this)
  return this.queue.addTask({ method: 'GET', url })
}

/**
 * Create a resource defined by the `service`.
 *
 * @param  {Object} body - The payload described by the related API resource.
 * @throws If `body` is missing.
 * @return {Promise} A `task` promise that will eventually be resolved.
 *
 * @example
 *
 * ```js
 * service = client.products
 * service.create({
 *   name: { en: 'Foo' },
 *   slug: { en: 'foo' },
 *   productType: { id: '123', typeId: 'product-type'}
 * })
 * .then()
 * .catch()
 * ```
 */
export function create (body) {
  if (!body)
    throw new Error('Body payload is required for creating a resource')

  // TODO: allow to pass `expand` query params
  const url = buildAbsoluteUrl(this.options, this.baseEndpoint)

  setDefaultParams.call(this)
  return this.queue.addTask({ method: 'POST', url, body })
}

/**
 * Update a resource defined by the `service`.
 *
 * @param  {Object} body - The payload described by the related API resource.
 * @throws If `body` and `id` are missing.
 * @return {Promise} A `task` promise that will eventually be resolved.
 *
 * @example
 *
 * ```js
 * service = client.products.byId('123')
 * service.update({
 *   version: 1,
 *   actions: [{ action: 'setName', name: { en: 'Foo' }}]
 * })
 * .then()
 * .catch()
 * ```
 */
export function update (body) {
  if (!body)
    throw new Error('Body payload is required for updating a resource.')
  if (!this.params.id)
    throw new Error('Missing required `id` param for updating a resource. ' +
      'You can set it by chaining `.byId(<id>).update({})`')

  const endpoint = `${this.baseEndpoint}/${this.params.id}`
  // TODO: allow to pass `expand` query params
  const url = buildAbsoluteUrl(this.options, endpoint)

  setDefaultParams.call(this)
  return this.queue.addTask({ method: 'POST', url, body })
}

/**
 * Delete a resource defined by the `service`.
 *
 * @param  {number} version - The current version of the resource.
 * @throws If `version` and `id` are missing.
 * @return {Promise} A `task` promise that will eventually be resolved.
 *
 * @example
 *
 * ```js
 * service = client.products.byId('123')
 * service.delete(1)
 * .then()
 * .catch()
 * ```
 */
function _delete (version) {
  if (!version)
    throw new Error('Version number is required for deleting a resource.')
  if (!this.params.id)
    throw new Error('Missing required `id` param for deleting a resource. ' +
      'You can set it by chaining `.byId(<id>).delete(<version>)`')

  const endpoint = `${this.baseEndpoint}/${this.params.id}?version=${version}`
  const url = buildAbsoluteUrl(this.options, endpoint)

  setDefaultParams.call(this)
  return this.queue.addTask({ method: 'DELETE', url })
}
export { _delete as delete }