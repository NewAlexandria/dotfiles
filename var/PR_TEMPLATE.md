
#### What this PR does

#### Design and Structure
Describe any new patterns that you introduced.
Indicate anything temporary or undesirable long-term.  If there is a planned future point where a pattern introduced will not work for us.

#### Background and context

#### Screenshots
(if appropriate)

#### Testing
*Main part to focus on*
*Gotchas*

#### Practice Checklist:
Remove anything not part of this PR.  [Wiki page for this doc is here](https://adsixty.atlassian.net/wiki/display/MBF/Review+for+Code+PRs)

##### SEO
- [ ] Correct H1,H2,H3... structure in the page's raw source.
- [ ] Semantic tags for sections.
- [ ] Semantic tags for business objects (products, reviews, etc).

- [ ] Redirecting any changed URLs.  Confirmed with directors.

##### UI
- [ ] Page or component was made responsive.
- [ ] Images were deflated, and sized for @2x.
- [ ] CDN images were given a cache expiry.
- [ ] Below-the-fold page components were put into a separate CSS file.

##### Reporting
- [ ] New GA events were added for UI or pages.
- [ ] Appropriate logging was added for exceptions.

##### QA
- [ ] A unit test was added. (jasmine or rspec)
- [ ] An integration test was added. (cucumber or rspec)

##### Team
- [ ] The [wiki / knowledge base](https://adsixty.atlassian.net/wiki/display/MBF/MyBank+Tracker+4.0+Home) was updated.

##### Stability
- [ ] Schema changes include patch for BT-441 indices.
- [ ] New dependencies were measured for memory impact.
- [ ] [Pagespeed measured](https://developers.google.com/speed/pagespeed/insights) using IP tunnel service ([\[1\]](http://localtunnel.me/), [\[2\]](https://ngrok.com/))
- [ ] New infrastructure was documented for Disaster Recovery.

