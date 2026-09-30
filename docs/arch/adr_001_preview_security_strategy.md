# Decision record: Why we use the Shareable preview with JWT method for FCM

## Context
We know that single points of contact (SPoCs) and subject matter experts (SMEs) need access to not yet pubished information in order to check it for 
factual accuracy. To this end we need to provide them with a secure way to access this information 
without requiring a SignOn account, as SMEs may not have a SignOn account.

We know this need also exists in [Whitehall](https://github.com/alphagov/whitehall) and [Content Reuse](https://github.com/alphagov/content-block-manager), so multiple teams are solving for this 
problem, and by solving in the same way we are providing a consistent security implementation. This consistency 
allows for a predictable work flow, which reduces risk of human error.

We know the key risks are that information that should not be publicly available becomes publicly shared prior to publishing
with potential reputational risk for the Government.

## Decision
Given that shareable preview method using JWTs is the agreed security approach across GOV.UK Publishing apps, we are continuing 
to follow this pattern. This is because the limited risks of the approach, listed below, can be managed and mitigated.

### Risks
| Risk                                                                                                                   | Likelihood | Mitigation                                                                                                                                                                                  |
|------------------------------------------------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Shareable previews links are created for all items - there is a small risk that someone could guess/brute force a link | Low        | They are protected with a randomly generated token. The generated token is cryptographically signed, so is well protected from tampering and brute force attempts.                          |
| Shareable previews could be used to bypass access limiting                                                             | Medium     | Only people who can send a Fact Check can trigger provision of the shareable preview link. Publishers will be able to request revoking of the link.                                         |
| Someone could accidentally share the preview link with someone who shouldn’t have access                               | Medium     | Publishers will be able to request revoking of the link.                                                                                                                                    |
| Publisher may be unaware that the link can be accessed by everyone.                                                    | Low        | Publisher needs to copy a specific shareable preview link. Copy makes it clear to Publisher that no login will be needed and that they are responsible for who they share fact checks with. |

## Consequences

There still is possible risk that a user who should not have access to the link gets it (for example if accidentally 
sent to the wrong email). Currently, this is mitigated through the provision of a rake task developers can run to revoke 
the link if needed, in future this will be expanded to be a task publishers can autonomously enact if needed. 

Similar security measures are already in place for draft previews, so any tightening of security approach should be applied 
to both features.

Ideally in future all users will access FCM through SignOn to allowed for audited collaboration, and to further reduce 
risk of sharing draft information.