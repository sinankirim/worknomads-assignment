# WorkNomads Senior Salesforce Developer - Take Home Assignment

This is my submission for the take home assignment given by WorkNomads,
which is for their Senior Salesforce Developer position. The assignment
assumes that I am working for Acme Services, a company that handles
support requests for consumer products. Acme wants to:
1. Enable agents to quickly create Service Requests for customers.
2. Provide AI-powered automated assistance using Agentforce (Einstein Service
Replies / AI Actions).

## Setup

### Prerequisites

- **Salesforce CLI** (`sf`) — install instructions:
  https://developer.salesforce.com/tools/salesforcecli
- **A target org** — either:
  - A Developer Edition org with Einstein and Agentforce enabled, or
  - A scratch org created from a Dev Hub with the appropriate features
    (see `config/project-scratch-def.json`).
- **Git** — to clone the repository.

The org must have the following enabled before deployment:

- **Einstein Generative AI** (Setup → Einstein Setup → toggle on)
- **Agentforce** (Setup → Agentforce → toggle on)
- **Prompt Builder** (typically enabled with Einstein)

If you're using a Developer Edition org and these aren't available, you
may need a Trailhead Playground with Agentforce features instead.

### Deploy the metadata

Clone the repository and authenticate to your target org:

```bash
git clone https://github.com/sinankirim/worknomads-assignment
cd worknomads-assignment

sf org login web --alias acme-dev --set-default
```

Deploy the project metadata (custom object, Apex classes, LWC, Flow,
permission set):

```bash
sf project deploy start --target-org acme-dev
```

Run the test suite to verify the deployment:

```bash
sf apex run test --target-org acme-dev --code-coverage --result-format human --wait 10
```

You should see all tests passing with code coverage above 90% on the
service layer.

### Alternative method: Deploy via ZIP file

If you have a ZIP file, you can skip this preliminary step. If you did not get a ZIP file, download it through **Code → Download ZIP** on the GitHub repository page.

1. Go to Workbench, log in to your target environment (Production or Sandbox), and choose the appropriate API version.
2. Click on Migration > Deploy.
3. Choose your .zip file. Select Single Package if your zip contains a single package.xml at the root.
4. Set Rollback On Error to true for production deployments.
5. Click Next and then Deploy.

For more information, you can visit: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/file_based_zip_file.htm

### Configure Agentforce

Some Agentforce metadata (the agent itself, subagent topic configuration,
action input/output bindings) may not deploy reliably via
Salesforce DX. In such cases, the following steps must be completed manually in the
target org's UI:

1. **Open the agent in Agentforce Studio.**
   Setup → Agentforce Studio → Agents → open
   **Service Request Resolution Agent**.
   *(If the agent didn't deploy, create a new Custom Agent with this
   name and a single subagent called "Draft Resolution Notes.")*

2. **Verify the subagent's actions.**
   The "Draft Resolution Notes" subagent should have two actions
   attached:
   - `Generate Resolution Notes` (Flow action, calls the Run_Resolution_Note_Prompt flow)
   - `Resolve Service Request` (Flow action, calls the Resolve_Service_Request_Flow flow)

   If either is missing, add it from the action library.

3. **Activate the agent.**
   Click *Activate* in the top-right of Agent Builder. The agent must
   be activated before it appears in the Einstein sidebar.

## Requirements

### Section 1 - Data Model and Business Logic

I created the custom object Service_Request__c with the following fields:

| Field | Type | Notes |
|---|---|---|
| `Name` | Auto Number | Format: `SR-{0000}` |
| `Customer_Email__c` | Email | Required |
| `Status__c` | Picklist | Values: New, In Progress, Resolved |
| `Description__c` | Long Text Area | |
| `Resolution_Notes__c` | Long Text Area | |
| `Priority__c` | Picklist | Values: Low, Medium, High |

Additionally, I also implemented an Apex service layer (**ServiceRequestHandler**) for the object which does the following:
- Resolve Service Requests with a Map input of Service Request IDs and corresponding Resolution Notes
- Resolve a single Service Request with a corresponding Resolution Note
- Resolve a single Service Request (given by its Id) with a corresponding Resolution Note
- Resolve multiple Service Requests given as a list with their corresponding Resolution Notes also given as a list

The first method is the main method, therefore all other methods are variations of the first one. This ensures reusability and bulk safety.

### Section 2 - Lightning Web Component

The component can be found under lwc → **serviceRequestForm**. It has three input fields: Customer Email, Description and Priority. If the email field is left blank, it shows an error and does not allow the user to create a Service Request. When a Service Request record is successfully created, it displays a link to the new record embedded in its ID. It also displays the 5 most recent Service Requests under the accordion subsection titled **Recent Requests**.

The Apex controller layer for this component is named **ServiceRequestFormController**.

To try the Lightning Web Component:
1. Navigate to any Lightning Record Page (e.g., a Home page or App Page)
   in the App Builder.
2. Drag the `serviceRequestForm` component onto the page.
3. Save and activate.
4. Submit a test Service Request.

### Section 3 - Agentforce

This might be difficult to set up using standard DX methods and may require manual configuration.

1. Navigate to Setup → Agentforce Studio → Agents.
2. Open the **Service Request Resolver** agent (or create a new Custom Agent
   if it didn't deploy).
3. Verify the **Draft Resolution Notes** subagent has the two actions
   `Generate Resolution Notes` (Flow) and `Resolve Service Request`
   (Flow) attached.
4. Activate the agent.

I picked Option B for this (Create an AI Action that enables an agent to resolve a request with AI-generated notes). To design and deploy the agent, I used a single subagent other than the Agent Router: Draft Resolution Note. Its instructions are written as:

```
GOAL: Help the user resolve Service Request records by generating draft Resolution Notes and, on confirmation, marking the request Resolved.

ACTION SEQUENCE — follow in order. Do not skip steps.

Step 1 — Generate draft notes.
  - When the user asks to resolve a Service Request, find:
  - If either is missing, ask the user for what's missing and stop. Do not invent a number or fabricate resolution details.
  - Call ​Generate Resolution Notes​ with the Service Request Number (give this parameter as serviceRequestNumber) and Resolution Details (give this parameter as resolutionDetails).

Step 2 — Handle the response.
  - If isFound is false, tell the user no Service Request with that number exists, and stop.
  - If isFound is true and isResolved is true, tell the user the request is already resolved, and stop. Do NOT present any Resolution Notes, there are none to present.
  - If isFound is true and isResolved is false, present the generated Resolution Notes to the user and ask for explicit confirmation before resolving.

Step 3 — Resolve.
  - Only after the user explicitly confirms (e.g., "yes", "go ahead", "resolve it"), call ​Resolve Service Request​.
  - Never call ​Resolve Service Request​ without notes.
  - Never call ​Resolve Service Request​ before ​Generate Resolution Notes​.

CONSTRAINTS
  - Never invent a Service Request Number or fabricate resolution details. Both must come from the user.
  - Resolution Notes passed to ​Resolve Service Request​ must be the notes generated by ​Generate Resolution Notes​ (or a version of them edited by the user during confirmation).
```

The `Generate Resolution Notes` Flow action calls a Flow called Run Resolution Note Prompt, which calls two things: the **ServiceRequestGetterInvocable** Apex class and the **Generate Resolution Notes for Service Requests** Flex prompt template. I wanted these to be tied together in a single action because I wanted them to run together when an input to resolve a Service Request was received: *"I want to resolve SR-0011. The phone screen was replaced."*

The `Resolve Service Request` Flow action calls a Flow called Resolve Service Request Flow, which calls an Apex class called **ServiceRequestResolverInvocable**, which updates the given Service Request with the AI-generated Resolution Notes through the aforementioned **ServiceRequestHandler** class.

My central design principle was: **the LLM handles natural language (extracting the Service Request number from the user's message, asking for confirmation, formatting the response), and Flow/Apex handle anything that must be exactly correct**. Therefore, the Flow actions handle the lookups and the check for whether the mentioned record exists or not, is resolved or not etc (isFound and isResolved flags). If isFound is true (record exists) and isResolved is false (status is not equal to Resolved), the agent displays the Resolution Notes generated by the prompt template. If the user confirms, the agent goes ahead with the update by calling the `Resolve Service Request` Flow action.

If the Service Request number is given without any resolution details (e.g. *"I want to resolve SR-0011"*), the agent asks for the resolution details before proceeding. If the 

I used Flows to wrap Apex classes because an earlier approach of using Apex actions to directly call @InvocableMethod methods caused the agent to hallucinate and bypass all Apex actions. Using Flows so that the agent could work in system context removed these hallucinations.

### Section 4 - Testing and Quality

I observed that all test classes are valid and the test coverage is 100% across all Apex classes, which meets the 90% requirement. The test classes are:
- ServiceRequestFormControllerTest
- ServiceRequestGetterInvocableTest
- ServiceRequestHandlerTest
- ServiceRequestResolverInvocableTest

I tested these classes in scenarios such as:
- Happy path, Service Request(s) is/are Resolved without any errors
- Bulk, 2 or more Service Requests being Resolved at once
- Negative cases (e.g. Customer Email is not given for the Service Request to be created)

## Assumptions
- I treated the status flow as `New → In Progress → Resolved` and disallow re-resolving an already-Resolved request. The assignment didn't specify, but this matches typical service workflows.
- In **Section 2 - Lightning Web Component**, I assumed that the display for the five most recent Service Requests would rather be hidden in an accordion component. I also did not employ any best UI/UX design practices as it was not asked for in the document.
- In **Section 3 - Agentforce**, I assumed that the correct way to run the agent is to provide the Service Request number and the details for resolution: *"I want to resolve SR-0011. The phone screen was replaced."*. I also assumed that asking the agent to resolve nonexistent Service Requests, or existing Service Requests without any resolution details (e.g. *"I want to resolve SR-0011."*) would fail to properly trigger the `Generate Resolution Notes` action. Based on these assumptions, I did not code a response to completely unrelated prompts that may be given by the user (e.g. *"I want pancakes"*).
