# API Reference

Fact check manager has a readily accessible API for use from other applications within the govuk ecosystem. Here is the
API reference for quick lookup.

## New Request
For when a document does not exist inside Fact Check Manager and needs to be created.

| Field                | Type     | Description                                                                | Note                                    |
|:---------------------|----------|----------------------------------------------------------------------------|-----------------------------------------|
| source_app           | string   | App name e.g. `publisher`                                                  | Becomes part of the URL for the request |
| source_id            | uuid     | UUID representing the original content source                              | Becomes part of the URL for the request |
| requester_name       | string   | Name of the user making the fact check request                             |                                         |
| requester_email      | string   | Email of the user making the fact check request                            |                                         |
| deadline             | datetime | The deadline for the fact check request                                    |                                         |
| reason_for_change    | string   | The given reason for the changes made between the old and new version      |                                         |
| zendesk_number       | string   | Zendesk ticket number to link to the request                               |                                         |
| recipients           |          | TODO:                                                                      |                                         |
| current_content      | json     | TODO:                                                                      |                                         |
| previous_content     | json     | TODO:                                                                      |                                         |
| source_url           | string   | URL for source content                                                     | Optional                                |
| source_title         | string   | Title for source content                                                   | Optional                                |
| draft_content_id     | uuid     | If a draft document exists, this is for its content ID                     | Optional                                |
| draft_auth_bipass_id | uuid     | Used for when a draft should be linkable without requiring login to signon | Optional                                |
| draft_slug           | string   | If a draft document exists, this is for its slug e.g. `/draft-document`    | Optional                                |

## Update Request
An update request is explicitly for updating an existing fact check with the newest version of the document and is thus
a much smaller payload

| Field                | Type                                                                       | Note     |
|:---------------------|----------------------------------------------------------------------------|----------|
| current_content      | TODO:                                                                      |          |
| source_title         | Title for source content                                                   | Optional |
| draft_auth_bipass_id | Used for when a draft should be linkable without requiring login to signon | Optional |
| draft_slug           | If a draft document exists, this is for its slug e.g. /draft-document      | Optional |

## Response Path
TODO: Currently this is very Publisher specific, need to discuss how this will actually work if agnostic?