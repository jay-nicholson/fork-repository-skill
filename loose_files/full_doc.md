Feedback on GLEAN Proposal
What There is to Like
1. Direct Revenue Linkage The validation question isn't theoretical—it cuts straight to the addressable revenue opportunity sitting dormant in your member base. This is exactly the kind of "find money hiding in our data" thinking BrightMatch needs right now.
2. Engineering Leverage You've got engineers spending cycles answering ad-hoc data questions instead of building product. GLEAN flips that—one investment unlocks self-serve for the whole team. That's compound ROI.
3. Simplicity-First Architecture The Vercel insight (17 tools → 1 tool = 80% → 100% accuracy) shows mature thinking. Resisting the urge to over-engineer is hard. The YAML semantic layer approach is elegant.
4. Addresses Real Pain QuickSight's AI features have been underwhelming. This isn't a solution looking for a problem—the team genuinely struggles to get answers without bothering Macklin or Shivam.

Critical Feedback
1. Hallucination Risk = Business Risk When an AI confidently tells you "33,500 members want consolidation" and that number is wrong because it misunderstood a join or filtered incorrectly, decisions get made on bad data. What's the confidence scoring mechanism? How does it communicate "I'm 60% sure about this query"?
2. The Maintenance Tax The YAML data catalogue sounds simple, but it becomes a second source of truth. Every time Redshift schema changes, someone needs to update the catalogue. Who owns this? What happens when it drifts? This is the hidden cost that kills internal tools.
3. The "Last Mile" Problem Getting 80% accuracy is achievable. Getting from 80% to 95%+ is brutal. If the team uses GLEAN ten times and gets three wrong answers, they'll stop trusting it and go back to asking engineers. What's the accuracy bar for launch, and how do you measure it?

Missing Pieces
1. Feedback Loop How does the system learn when it's wrong? There's no mention of a "👎 this answer is incorrect" mechanism that feeds back into prompt refinement or catalogue updates.
2. Cost Modelling What's the per-query cost (LLM API + Lambda + Redshift compute)? If it becomes popular and the team runs 500 queries/day, does that blow up your API budget?
3. Caching & Common Queries "How many FOBMs this month?" will get asked constantly. Are you caching common queries? Pre-computing popular metrics?
4. Audit Trail For compliance and governance—who asked what, when, and what answer did they get? If a business decision goes sideways, can you trace it back to the data query that informed it?
5. Testing Framework How do you validate before launch? You need a test suite of 50+ questions with known correct answers to benchmark accuracy.

The Deeper Challenge: From Numbers to Actions
Here's where I want to push the thinking further.
The Validation Question Needs Extending
The current golden question is good: "How many members stated they want debt consolidation during onboarding, and what percentage have applied to BrightMatch?"
But it doesn't go far enough. The real question chain is:
How many members stated debt consolidation as a goal?
Of those, how many should consolidate because it would genuinely save them money?
Of those, how many can get approved based on our lender criteria?
Of those, how many haven't applied yet?
What's the best action to convert them?
That final group—high intent, high approval probability, genuinely beneficial, not yet converted—is the gold. And the output shouldn't be a number. It should be a personalised refinance carousel, an email, a push notification that's so precisely curated it surprises and delights the member because of how accurate it is.
That's the difference between a reporting tool and a revenue engine.
Low-Value vs High-Value Questions
Consider two questions:
"What was CAC yesterday?" → Low value. I can find this in Slack in two clicks.
"CAC yesterday was $57—why?" → High value. This requires understanding what CAC is, its subcomponents (spend by channel, install rates, conversion rates), the relative context of yesterday vs the week prior, and what to investigate next.
GLEAN needs to handle the second type, not just the first. Otherwise it's a fancy calculator, not an intelligence layer.
Not All Questions Are SQL
Some of the most valuable questions won't translate to a database query:
"Tell me the members who saved over $2,000 by switching to a cheaper alternative on BrightMatch—and generate a personalised email asking for a testimonial."
This requires:
Querying savings data
Understanding the business context (testimonials → social proof → higher RPM)
Generating personalised outreach
Potentially triggering an action (send the email)
Visualisations are cool, but can visualisations directly translate to business value? Finding information is step one. Knowing what to do with it next—that's the game changer.
Think About Your Actors
Marj sits down and asks: "How do I create an ad that's going to resonate with real-life situations based on our actual membership base? Something so personalised and relevant it drives more BrightMatch applications because we're hitting the mark on how we understand our members."
That's not a SQL query. That's a value chain:
Member data → Insight about pain points → Creative brief → Ad execution → Conversion lift
GLEAN should eventually support that entire arc, not just the first step.
E.g. Recent example with Claude/Amplitude:




Why Taxonomies, Ontologies, and Semantic Layers Are Critical
This is where I want to challenge the team to think bigger. A YAML data catalogue is a good start, but it's not an ontology. And that distinction matters enormously.
The Difference Between a Data Catalogue and an Ontology
A data catalogue says: "This field is called usr_crd_scr, it's an integer, it lives in the member_financial table."
An ontology says: "This represents a Member's creditworthiness. Creditworthiness is derived from credit bureau data, updated monthly, and is a key predictor of loan approval probability. It relates to Lender Criteria through approval thresholds. Members with scores below 600 have limited options. A score improvement of 50 points typically unlocks 3-4 additional lenders."
The first is schema documentation. The second is business meaning.
What Palantir Got Right
Palantir's Foundry platform is built entirely around this concept. Their Ontology isn't just a data layer—it's what they call a "digital twin of the organisation." It sits on top of raw data and connects technical assets to their real-world counterparts.
Their architecture has three layers that GLEAN should learn from:
Semantic Layer — Defines what exists: Objects (Member, Lender, Application), Properties (credit score, income, approval status), and Links (Member → submits → Application → evaluated by → Lender). This is your "what are the things that matter in our world?"
Kinetic Layer — Defines what can be done: Actions and Functions. Not just "show me members with 80% utilisation" but "send those members a personalised consolidation offer." The ontology enables change, not just reporting.
Dynamic Layer — Defines how it adapts: Security, governance, and evolution over time. Who can see what? What happens when definitions change?
This is why Palantir customers say things like: "Once you map something to the ontology, you never have to argue again about what a 'customer' actually means." Everyone—analysts, engineers, executives, AI agents—speaks the same language.
Why This Matters for GLEAN
Right now, GLEAN is proposing a semantic layer (good) but stopping short of a true ontology. Consider the difference:
Data Catalogue Approach
Ontology Approach
member.onboarding_goal = text field
Goal is an object type with properties (stated intent, confidence, timestamp) that links to Member and predicts Product Fit
lender_rules.min_credit_score = integer
Lender Criteria is an object that links to Lender, defines Approval Threshold, and can be queried as "which lenders would approve this member?"
Tables and columns
Objects, relationships, and actions
Answers questions
Enables decisions

The Palantir insight is that LLMs and AI agents can directly query and reason over the ontology using natural language because objects, properties, and links have clear business meaning. Supply Chain Today That's why their AIP platform works—the AI doesn't need to understand SQL joins, it needs to understand that a "Customer" has "Orders" which have "Risk Factors."
Ontology vs. Semantic Layer
The Critical Distinction
Jessica Talisman's insight (from "Ontologies, Context Graphs, and Semantic Layers: What AI Actually Needs in 2026"):
"In 2012, Looker launched with LookML and a vision: define your metrics once, and business users could self-serve without SQL. Around the same time, life sciences, healthcare, and research organizations were building formal ontologies and knowledge graphs to model their data and their domains."
"Both approaches promised to make data meaningful. A decade later, one powers dashboards. The other powers drug discovery that identifies cancer treatments, clinical decision support that prevents fatal drug interactions, and AI reasoning systems that intelligence agencies trust with life-or-death decisions."
"One gave us prettier reports. The other gave us machines that can actually reason about meaning. Did we fundamentally misunderstand the problem we were trying to solve? AI is about to force a reckoning."
The WeMoney Ontology (Sketch)
Before building the data catalogue, map the ontology first. Here's a starting point:
Core Object Types:
Member — A person using WeMoney
Financial Profile — CDR-derived snapshot of a member's financial state
Goal — What the member wants to achieve (debt consolidation, savings, etc.)
Application — A BrightMatch submission
Lender — A lending partner
Lender Criteria — Rules defining who a lender will approve
Product — A specific loan/credit product
Offer — A matched product for a specific member
Engagement Signal — App opens, email clicks, push responses
Key Relationships:
Member → has → Financial Profile
Member → stated → Goal
Member → submitted → Application
Application → evaluated by → Lender Criteria
Lender Criteria → belongs to → Lender
Member → matched to → Offer
Offer → for product → Product
Key Derived Properties:
Approval Probability = f(Financial Profile, Lender Criteria)
Savings Potential = f(Current Debt, Available Offers)
Conversion Likelihood = f(Goal Alignment, Engagement Signals, Approval Probability)
Actions (Kinetic Layer):
generate_personalised_offer(member) → Creates carousel
send_nudge_email(member, template) → Triggers comms
request_testimonial(member) → Outreach to high-savers
flag_for_review(member, reason) → Human escalation
This is the difference between asking "how many members have goal = debt_consolidation?" and asking "which members should receive a personalised consolidation offer this week, and what should that offer say?"

Bonus: Mining Slack for Ontological Truth


Here's a tip worth considering: think about all our Slack conversations over the years. There's an evolution of thinking in those threads—debates about what metrics mean, why we built things certain ways, what "FOBM" actually represents, how we define "active." That corpus is tribal knowledge.


Palantir's approach would say: that tribal knowledge should be encoded in the ontology, not lost in Slack threads. When someone asks "what's an FOBM?", the ontology should return not just a definition but the context, the edge cases, the history.
You could even use our Slack history to train GLEAN on WeMoney-speak. The common vernacular, the abbreviations, the implicit assumptions—that's what makes the difference between an AI that understands databases and an AI that understands WeMoney.


Domain-First Thinking
Before building the data catalogue, map the domains first:
Domain
Source
Value
Ontology Objects
Product behaviour
Amplitude
What members actually do
Engagement Signal, Session, Feature Usage
Stated intent
Onboarding surveys
What members say they want
Goal, Preference
Financial profile
Redshift (CDR data)
What members can afford
Financial Profile, Transaction, Account
Lender criteria
Rules engine
What members can get approved for
Lender, Lender Criteria, Product
Engagement signals
App events, email opens
Who's ready to act
Engagement Signal, Campaign Response
Historical conversations
Slack, support tickets
Contextual intelligence
(Training corpus, not queryable objects)

The magic happens when you interconnect these domains. A number like "20,000 members with 600 credit scores" is only useful to the degree it presents a number. It won't tell you what to do next.
But when you layer:
Credit score (600) → Financial Profile
Utilisation rate (>80%) → Financial Profile
Onboarding goal (debt consolidation) → Goal
Engagement signal (opened BrightMatch email last week) → Engagement Signal
Lender match (3 lenders would approve) → Lender Criteria
Now you have Mary—a real person with a specific situation who will receive a personalised card that surprises and delights her because of its precision. That precision becomes a programmatic endpoint. That endpoint drives funnel conversion. That conversion lifts RPM.

The Value Chain Explainer
Here's what I'd like to see articulated: the value chain from question to outcome.
Actor
Question
Data Required
Insight
Action
Business Value
Dan
"Why was CAC $57 yesterday?"
Marketing spend, installs, conversions by channel
Facebook CPA spiked 40% due to audience fatigue
Refresh creative, reallocate to TikTok
CAC back to $45 = $12k/month saved
Marj
"What ad hooks resonate with our best converters?"
High-RPM member attributes, onboarding goals, demographics
68% of high-converters cited "taking control" as motivation
Create "Take Control" campaign
15% lift in BrightMatch applications
Matt
"Who should get a personalised consolidation push?"
Goal, approval probability, engagement recency, savings potential
4,200 members are high-intent, approvable, engaged, not converted
Trigger personalised push campaign
$840k addressable revenue at $200 RPM
Ops
"Who saved $2k+ and would give a testimonial?"
Savings calculations, NPS scores, engagement
312 members saved $2k+, 89 have NPS 9-10
Send testimonial request
20 new testimonials → social proof → higher conversion

This is the thinking I want to see embedded in GLEAN's design. Not "what tables can I query?" but "what value can I unlock?"

Ways to Extend This
1. Claude Integration @glean How many members applied to BrightMatch yesterday? directly reduces friction to zero.
2. Scheduled Insights "Every Monday at 8am, tell me: approval rate, high-intent unconverted members, top decline reasons." Proactive intelligence, not just reactive queries.
3. Alert Triggers "Notify #brightmatch-alerts if daily approval rate drops below 55%." Turns GLEAN from a query tool into a monitoring system.
4. Action Endpoints (Kinetic Layer) Query → Insight → Trigger. "Find members who saved $2k+ and send them the testimonial request email." GLEAN becomes an orchestration layer, not just a read layer. This is Palantir's "Actions" concept—the ontology doesn't just describe the world, it enables you to change it.
5. Creative Intelligence for Marj "Based on our top-converting member segments, generate three ad hook concepts that speak to their actual situations." Data-informed creative, not guesswork.
6. The Mary Journey (Persona-Based Activation)
Mary downloads WeMoney after seeing an ad about taking control of her money
She sets debt consolidation as her goal during onboarding
Her CDR data shows 82% credit utilisation
GLEAN identifies her as high-intent, approvable, and not yet converted
She receives a personalised push: "Mary, based on your goals and situation, we found 3 lenders who could consolidate your debt and save you $247/month"
She applies, gets approved, leaves a testimonial
That testimonial goes into the next ad cycle
Flywheel spins
7. Lender Rule Interpreter Same NL approach applied to lender criteria: "Which lenders would approve a member with $80k income, 650 credit score, and $40k existing debt?" This is the natural extension toward BrightMatch intelligence.
8. Cross-Reference with Matthew's Dashboard Work The Member Dashboard PRD Matthew submitted—can GLEAN power the backend queries for that? Synergy between the two hack day projects.

Summary
This is a strong proposal with clear commercial thinking. The architecture is sound and the simplicity-first approach is right.
Where I want to push:
Extend beyond retrieval to action-oriented outcomes
Think about the value chain: Question → Insight → Action → Business Result
Map domains first before building the catalogue
Build an ontology, not just a data catalogue—learn from what Palantir has done with semantic, kinetic, and dynamic layers
Consider ontological meaning, not just technical schema
Mine our Slack history for tribal knowledge and common vernacular
Design for the "Mary journey"—personalisation at scale that surprises and delights
The revenue insight (high-intent members not converting) justifies building this. But the real unlock is when GLEAN doesn't just tell you the number—it tells you what to do next, and eventually does it for you.
As Palantir users say: "The first time an AI agent correctly answered 'Which rigs are down right now and who's responsible?' using only natural language… I got chills." That's the bar. For us it's: "Which members should get a consolidation offer today and what should it say?"
Part 14: 10 Companies That Solved This Problem
1. Uber – QueryGPT
Problem: 1.2M interactive queries/month requiring SQL expertise + deep internal data model knowledge
Solution: LLM + vector databases + similarity search to generate complex queries from natural language
Key Innovation:
Intent Agent maps questions to business domains/workspaces
Table Agent picks right tables (user can ACK or edit)
Column Prune Agent removes irrelevant columns to avoid token limits
Evaluation Metrics: Intent accuracy, Table Overlap Score (0-1), Successful Run, Run Has Output
Link: https://www.uber.com/blog/query-gpt/

2. Airbnb – Minerva + Dataportal
Problem: Executives asking "which city had most bookings last week" got diverging answers from Data Science vs Finance teams
Solution:
Minerva = metrics platform (12,000+ metrics, 4,000+ dimensions) as single source of truth
Dataportal = data catalog with Neo4j graph database for discovery
Key Innovation:
Metrics defined once in centralised GitHub repo
Consumed across dashboards, experimentation, ML, ad-hoc analysis
Graph-based search using PageRank to surface high-quality resources
Architecture: Airflow (orchestration), Hive/Spark (compute), Presto/Druid (consumption)
Links:
https://medium.com/airbnb-engineering/how-airbnb-achieved-metric-consistency-at-scale-f23cc53dea70
https://medium.com/airbnb-engineering/democratizing-data-at-airbnb-852d76c51770

3. ThoughtSpot (+ Mode Acquisition)
Problem: Static dashboards don't meet needs of non-technical business users
Solution: Natural language search + AI-driven analytics. $200M acquisition of Mode to unite code-first (analysts) with search-first (business users)
Key Innovation:
ThoughtSpot Sage combines LLMs with patented search technology + semantic data model for accuracy
Mode's SQL/Python/R work automatically becomes foundation for semantic models
Integration: Databricks, Snowflake, BigQuery, Redshift
Links:
https://www.thoughtspot.com/blog/thoughtspot-acquires-mode
https://www.thoughtspot.com/dataspot

4. AWS – Text-to-SQL with Amazon Bedrock Agents
Problem: Enterprise environments with 100+ tables, complex schemas, need robust error handling
Solution: Amazon Bedrock Agents with RAG framework, similarity search for metadata, self-correcting queries
Key Innovation:
Agent autonomously analyses error messages, modifies queries, retries
Dynamic schema discovery when initial query fails
Athena validates syntax, error messages fed back to improve
Architecture: Vector store (OpenSearch) for metadata embeddings, Athena for validation, Claude for generation
Links:
https://aws.amazon.com/blogs/machine-learning/build-a-robust-text-to-sql-solution-generating-complex-queries-self-correcting-and-querying-diverse-data-sources/
https://aws.amazon.com/blogs/machine-learning/dynamic-text-to-sql-for-enterprise-workloads-with-amazon-bedrock-agents/

5. Google Cloud – Looker + Gemini
Problem: Text-to-SQL tools lack business context, are unreliable
Solution: Gemini works with Looker's semantic layer (LookML) ensuring AI outputs align with governed metrics
Key Innovation:
Conversational analytics via chat
Custom visualisation generation using natural language
Disambiguation using LLMs (clarifying questions when ambiguous)
Techniques: SQL-aware models, retrieval + in-context learning, multi-stage semantic matching
Link: https://cloud.google.com/blog/products/databases/techniques-for-improving-text-to-sql

6. Stripe – Sigma + AI Assistant
Problem: Users need custom SQL queries for business insights but lack expertise
Solution: Stripe Sigma = interactive tool with SQL templates + AI-powered chat assistant for natural language queries
Key Innovation:
Transform query results into dynamic charts with one click
Pre-written templates for common reporting needs
Scheduled queries for recurring reports
Use Cases: Finance (revenue reconciliation), Product (growth opportunities), Sales/Marketing (customer profiles)
Links:
https://stripe.com/sigma
https://stripe.com/guides/how-to-surface-business-insights-with-stripe

7. Sigma Computing
Problem: Specialised Python developers needed to analyse billion-row records
Solution: Spreadsheet-like interface + AI-powered logic + live warehouse data
Key Innovation:
"You're not using specialised Python developers anymore. You're just adding an Excel user."
AI Query with connected models from Snowflake/Databricks/BigQuery/Redshift
Call AI directly in workbook to enrich data, summarise, automate
ROI: Forrester TEI study found 321% ROI over 3 years, payback <6 months
Link: https://www.sigmacomputing.com/product/ai

8. Microsoft – Azure OpenAI Natural Language to SQL
Problem: Non-technical users (business analysts, marketers, executives) can't retrieve data without SQL knowledge
Solution: Azure OpenAI converts natural language to SQL, queries PostgreSQL, returns results
Key Innovation:
Proper prompts enable queries like "Get total revenue for all companies in London" without SQL syntax
Boosts productivity by eliminating need for technical experts
Link: https://learn.microsoft.com/en-us/microsoft-cloud/dev/tutorials/openai-acs-msgraph/03-openai-nl-sql

9. Cisco + AWS – Enterprise-Grade NL2SQL
Problem: Complex schemas optimised for storage (not retrieval), 100+ tables, diverse natural language queries, LLM knowledge gap
Solution: Pattern reducing processing required for SQL generation, allowing simpler/cheaper/faster models
Key Innovation:
Addresses nested tables, multi-dimensional data, complex domain-specific schemas
Generative accuracy paramount (inaccurate SQL = data leak or bad business decisions)
Link: https://aws.amazon.com/blogs/machine-learning/enterprise-grade-natural-language-to-sql-generation-using-llms-balancing-accuracy-latency-and-scale/

10. Lamini – Text-to-SQL with 95% Accuracy
Problem: LLMs prone to hallucinating without adequate domain context
Solution: Fine-tuning with Gold Dataset (20-40 input-output pairs to start), memory tuning for precision
Key Innovation:
Fortune 500 customer achieved 94.7% accuracy
Start small with quality over quantity, increase complexity over iterations
Why Not RAG: RAG unreliable for high-precision use cases (relies on similarity search, selectively chooses passages)
Link: https://www.lamini.ai/blog/use-case-text-to-sql

Part 15: Common Patterns Across Solutions
Architecture Components
Natural Language Understanding (intent detection, entity extraction)
Schema/Metadata Management (vector stores, semantic layers, ontologies)
SQL Generation (LLM-based with context)
Validation & Error Handling (self-correction loops)
Execution & Security (query guardrails, access controls)
Visualisation & Response (charts, dashboards, natural language summaries)
Critical Success Factors
Factor
Why It Matters
Business Context
Semantic layers alone insufficient—need ontologies for reasoning
Error Handling
Self-correcting loops essential (Athena validation, error message feedback)
Domain Mapping
Intent agents to narrow search radius (Uber's approach)
Governance
Single source of truth for metrics (Airbnb Minerva)
Evaluation
Gold datasets, accuracy metrics, table overlap scores
User Experience
Disambiguation (clarifying questions), confidence scoring, audit trails

Cost Considerations
Per-query LLM costs
Warehouse compute costs (ThoughtSpot concern: rising cloud expenditures)
Token optimisation (column pruning, schema simplification)

Strategic Recommendation
Phase 1: Prove Value on D0
Pick narrow domain (BrightMatch conversion investigation like Matt's example)
Build ontology for that domain
Test with real business queries
Measure: time saved, accuracy, RPM impact
Phase 2: Expand Domains
Add domains incrementally
Each domain proves additional value
Build interconnections between domains (the "Mary Journey")
Phase 3: Kinetic Layer
Move beyond query → add actions
Generate emails, trigger workflows, update records
This is where semantic layer → ontology pays off
Key Differentiator
Not just "prettier reports" but "machines that reason about meaning and drive action."

Appendix A: Extension Ideas
Intercomany integration – Query from where the team already works
Scheduled insights – Daily digest of key metrics with anomaly detection
Alert triggers – "Tell me when X crosses threshold Y"
Action endpoints (Kinetic Layer) – Not just insight, but execution
Creative intelligence for Marj – Which creative, which audience, which CTA
Lender rule interpreter – Natural language explanation of why someone was declined
Cross-reference with Matthew's Dashboard work – Unified view layer

Appendix B: Key References
Internal
Original GLEAN proposal document
Matt's conversion investigation workflow
BrightMatch approval rate documentation
External
Jessica Talisman, "Ontologies, Context Graphs, and Semantic Layers: What AI Actually Needs in 2026"
Palantir Foundry Ontology documentation
Vercel v0 simplicity-first architecture
Research Links
Uber QueryGPT: https://www.uber.com/blog/query-gpt/
Airbnb Minerva: https://medium.com/airbnb-engineering/how-airbnb-achieved-metric-consistency-at-scale-f23cc53dea70
Airbnb Dataportal: https://medium.com/airbnb-engineering/democratizing-data-at-airbnb-852d76c51770
ThoughtSpot: https://www.thoughtspot.com/dataspot
AWS Text-to-SQL: https://aws.amazon.com/blogs/machine-learning/build-a-robust-text-to-sql-solution-generating-complex-queries-self-correcting-and-querying-diverse-data-sources/
Google Cloud NL-to-SQL: https://cloud.google.com/blog/products/databases/techniques-for-improving-text-to-sql
Stripe Sigma: https://stripe.com/sigma
Sigma Computing: https://www.sigmacomputing.com/product/ai
Microsoft Azure OpenAI NL-to-SQL: https://learn.microsoft.com/en-us/microsoft-cloud/dev/tutorials/openai-acs-msgraph/03-openai-nl-sql
Cisco Enterprise NL2SQL: https://aws.amazon.com/blogs/machine-learning/enterprise-grade-natural-language-to-sql-generation-using-llms-balancing-accuracy-latency-and-scale/
Lamini Text-to-SQL: https://www.lamini.ai/blog/use-case-text-to-sql

