# Maintenance tasks

Due to the nature of Fact Check Manager there are some tasks we need available to us for various forms of maintenance either for security or process reasons.

## Revoke edition preview access for SMEs

Due to security requirements we need to manually reset the request's `auth_bypass_id` to invalidate preview links for any SMEs. We can do this by supplying a comma separated list of request IDs **or** source IDs to the [associated rake task](https://github.com/alphagov/fact-check-manager/pull/121/changes#diff-84ce051a6ca45ebf2ca70242f2b143f331c43aeb926b4344c862b68a425e3ac4).

For example:
`fact_check:revoke_preview_link_by_request_ids["request_id1","request_id2"]`
 **or** `fact_check:fact_check:revoke_preview_links_by_source_ids["source_id1","source_id2"]`

**Note:** You cannot mix source IDs and request IDs in the same rake task. Pick the one you need for your job!