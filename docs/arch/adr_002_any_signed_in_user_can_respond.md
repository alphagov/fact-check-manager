# Decision record: Why any signed in user can respond to a fact check

## Context
When a fact check request is created, FCM records each recipient email address as a collaborator on the request. Until
now, only collaborators and users with the `govuk_admin` permission could view a fact check while signed in, or respond
to one.

We expect some fact check requests to be sent to shared inboxes, such as a team mailbox. In that case, the person who
picks up the request and signs in will not be the recipient we hold a collaboration for. They would be blocked from
responding, and the request would stall.

## Decision
For launch, any user signed in through Signon with access to FCM can view and respond to a fact check. We do this by
making `AuthenticationHelper#check_permissions` always allow access, rather than removing it, so the check is easy to
reintroduce.

Users viewing a fact check with a shareable preview link (see [ADR 001](adr_001_preview_security_strategy.md)) still need
to sign in before they can respond.

### Risks
| Risk                                                                         | Likelihood | Mitigation                                                                                                                                              |
|------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| A signed in user could respond to a fact check that was not sent to them     | Low        | Fact check URLs contain the content ID (a UUID), so a user needs to know this along with the link structure to access a request. They cannot browse other requests, and cannot realistically guess a content ID.                 |
| A forwarded link could let the wrong person respond                          | Medium     | Responding requires a Signon account. The response is recorded against the user who submitted it, and their name is sent to Publisher with the response. |
| A response from the wrong person blocks the right person from responding     | Low        | Only one response is accepted per request. Publisher can send a new fact check request, which the intended recipient can then respond to.               |
| A different person with the same name as the intended reviewer responds to the fact check   | Low        | Publisher only logs the name of the person who responds to the fact check request (rather than their email or any other information). If a person with the same name as the intended reviewer were to inadvertently or maliciously respond to the fact check request, the Publisher user may not know that it was not the intended reviewer.               |

## Consequences
We no longer use collaborations to control access. They are still used to decide who receives the fact check request
emails.

We lose the guarantee that the person who responds is someone the publisher chose. We keep an audit of who did respond.

After launch, we should review how requests are being responded to and decide whether to reintroduce the collaborator
check, or a less strict version of it, for example allowing any user from the recipient's organisation.
