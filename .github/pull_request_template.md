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

## UAT Toggle (PRs to `main`)

- Add label `run-uat` to this PR to enable UAT deployment (`deploy-uat`).
- Remove label `run-uat` to skip UAT deployment.

## Risk / Rollback

- Risk level: low / medium / high
- Rollback plan:
