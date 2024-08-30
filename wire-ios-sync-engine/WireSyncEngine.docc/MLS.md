# MLS

This document covers the MLS implementation in WireSyncEngine. For a more general overview of MLS, see the documentation in WireDataModel.

## Overview

MLS functionalities in this project are limited to conference calls. 
You'll also find setup code for core crypto, the `MLSService`, and other objects in ``ZMUserSession``

### MLS Conferencing

- `WireCallCenter/setupMLSConference(in:)` sets up MLS conference calls. 
- `WireCallCenter+MLS` supports MLS-related call actions. 
- `MLSConferenceStaleParticipantsRemover` is responsible for removing stale participants.

Documentation of use cases can be found on confluence:
- [Start a conference call](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/616824954/Use+case+start+a+conference+call)
- [Answer a call (incoming)](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/616792280/Use+case+answer+a+call+incoming)
- [End a call (ongoing/outgoing)](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/616956023/Use+case+end+a+call+ongoing+outgoing)
- [Update AVS with current epoch info](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/681771131/Use+case+Update+AVS+with+current+epoch+info+MLS)
- [Join conference sub-conversation](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/692027483/Use+case+Join+conference+sub-conversation+MLS)
- [Remove stale participants](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/698908878/Use+case+remove+stale+participants+MLS)
- [Leave conference calls after a crash](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/699170905/Use+case+leave+conference+calls+after+a+crash+MLS)
- [Generate new epoch upon request](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/699236459/Use+case+generate+new+epoch+upon+request+MLS)
