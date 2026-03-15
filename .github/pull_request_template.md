# Pull Request Checklist

## Summary

- What changed?
- Why was it needed?

## Validation

- [ ] Local checks run (if applicable)
- [ ] Relevant workflow/jobs observed

## Deployment Notes

- [ ] No environment/config changes required
- [ ] Environment/config changes required (describe below)

## Staging Toggle (PRs to `main`)

- Add label `run-staging` to this PR to enable staging deployment (`deploy-staging`).
- Remove label `run-staging` to skip staging deployment.

## Risk / Rollback

- Risk level: low / medium / high
- Rollback plan:
