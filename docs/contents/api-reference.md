# API Reference

Fact check manager has a readily accessible API for use from other applications within the govuk ecosystem. Here is the
API reference for quick lookup.

## New Request
For when a document does not exist inside Fact Check Manager and needs to be created.

| Field                | Type     | Description                                                                | Note                                            |
|:---------------------|----------|----------------------------------------------------------------------------|-------------------------------------------------|
| source_app           | string   | App name e.g. `publisher`                                                  | Becomes part of the URL for the request         |
| source_id            | uuid     | UUID representing the original content source                              | Becomes part of the URL for the request         |
| requester_name       | string   | Name of the user making the fact check request                             |                                                 |
| requester_email      | string   | Email of the user making the fact check request                            |                                                 |
| deadline             | datetime | The deadline for the fact check request                                    |                                                 |
| reason_for_change    | string   | The given reason for the changes made between the old and new version      |                                                 |
| zendesk_number       | string   | Zendesk ticket number to link to the request                               |                                                 |
| recipients           |          | TODO:                                                                      |                                                 |
| current_content      | json     | A hash of current content to be compared in HTML format                    | See [hash format](#Hash Format) below           |
| previous_content     | json     | A hash of previous content to be compared in HTML format                   | Optional, See [hash format](#Hash Format) below |
| source_url           | string   | URL for source content                                                     | Optional                                        |
| source_title         | string   | Title for source content                                                   | Optional                                        |
| draft_content_id     | uuid     | If a draft document exists, this is for its content ID                     | Optional                                        |
| draft_auth_bipass_id | uuid     | Used for when a draft should be linkable without requiring login to signon | Optional                                        |
| draft_slug           | string   | If a draft document exists, this is for its slug e.g. `/draft-document`    | Optional                                        |

## Update Request
An update request is explicitly for updating an existing fact check with the newest version of the document and is thus
a much smaller payload

| Field                | Type                                                                       | Note                                  |
|:---------------------|----------------------------------------------------------------------------|---------------------------------------|
| current_content      | A hash of current content to be compared in HTML format                    | See [hash format](#Hash Format) below |
| source_title         | Title for source content                                                   | Optional                              |
| draft_auth_bipass_id | Used for when a draft should be linkable without requiring login to signon | Optional                              |
| draft_slug           | If a draft document exists, this is for its slug e.g. /draft-document      | Optional                              |

## Hash Format
Both `current_content` and `previous_content` use a hash of `id: content` pairs to allow for easy comparison of complicated
documents. For context, an example `current_content` is below:

```ruby
# { id: { heading: content } }
{
  ident_1: {
    "First Heading": "Content within first part <b>with html formatting</b>"
  }, 
  part_2: {
    "And another heading": "Content for `And another heading` portion with HTML formatting"
  }
}
```

The behaviour of Fact Check Manager will depend on the contents of this hash, and that of the `previous_content` hash.

- `previous_content` does not have to be supplied. This will mark the whole document as new and not render any comparison
highlighting in the [the diff view](flow_overview.md#the-diff-view).


- A document with one `id` in both hashes is considered a single part document
and rendered as such, whereas a document with multiple `id` fields in *either* hash is considered a multi-part. This
also applies if the `id` is different between the two single entry hashes.


- We use the `id` to determine matching parts of a document to compare against. This allows the ordering of the parts to
  change while still being valid for comparison.


- `id` can be any String value. The content of the `heading: content` pair does not matter, however in order for a part to
be compared to a previous entry, the ID must match in both `previous_` and `current_content` hashes.


- If an ID exists *only* in `previous_content`, FCM will mark the whole part as removed. If an ID exists *only* in 
`current_content`, the whole part will be marked as added.

> **Note:** The heading is effectively the title of a given chapter in a multipart document. 
> While a heading must be supplied in the hash, if there is only one entry in both `previous_` and
> `current_content`, the heading is not rendered in FCM. If there are more, the heading is rendered as parts of the
> document are separated in [the diff view](flow_overview.md#the-diff-view).

## Response Path
TODO: Currently this is very Publisher specific, need to discuss how this will actually work if agnostic?