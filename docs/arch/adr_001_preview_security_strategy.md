# Decision record: Why we use the Shareable preview with JWT method for FCM

## Context
We know that SPoCs and SMEs need access to not yet pubished information in order to check it for 
factual accuracy. To this end we need to provide them with a secure way to access this information 
without requiring a SignOn account.

We know this need also exists in Whitehall and Content Reuse, so multiple teams are solving for this 
problem, and by solving in the same way we are providing a consistent user experience. This consistency 
allows for a predictable work flow, which reduces risk of human error.

We know the key risks are that information that should not be publicly available becomes publicly shared 
with potential reputational risk for the Government.

## Decision
Given that Whitehall has already implemented a shareable preview method using JWTs, that is the approach 
we are taking too. This is because the limited risks of the approach, listed below, can be managed and mitigated.

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

Ideally in future all users will access FCM through SignOn to allowed for audited collaboration, and to further reduce 
risk of sharing draft information.