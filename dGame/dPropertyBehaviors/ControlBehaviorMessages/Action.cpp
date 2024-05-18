#include "Action.h"
#include "Amf3.h"

#include "tinyxml2.h"

Action::Action(const AMFArrayValue& arguments) {
	for (const auto& [paramName, paramValue] : arguments.GetAssociative()) {
		if (paramName == "Type") {
			if (paramValue->GetValueType() != eAmf::String) continue;
			m_Type = static_cast<AMFStringValue*>(paramValue)->GetValue();
		} else {
			m_ValueParameterName = paramName;
			// Message is the only known string parameter
			if (m_ValueParameterName == "Message") {
				if (paramValue->GetValueType() != eAmf::String) continue;
				m_ValueParameterString = static_cast<AMFStringValue*>(paramValue)->GetValue();
			} else {
				if (paramValue->GetValueType() != eAmf::Double) continue;
				m_ValueParameterDouble = static_cast<AMFDoubleValue*>(paramValue)->GetValue();
			}
		}
	}
}

void Action::SendBehaviorBlocksToClient(AMFArrayValue& args) const {
	auto* const actionArgs = args.PushArray();
	actionArgs->Insert("Type", m_Type);

	if (m_ValueParameterName.empty()) return;

	if (m_ValueParameterName == "Message") {
		actionArgs->Insert(m_ValueParameterName, m_ValueParameterString);
	} else {
		actionArgs->Insert(m_ValueParameterName, m_ValueParameterDouble);
	}
}

void Action::Serialize(tinyxml2::XMLElement& action) const {
	action.SetAttribute("Type", m_Type.c_str());

	if (m_ValueParameterName.empty()) return;

	if (m_ValueParameterName == "Message") {
		action.SetAttribute(m_ValueParameterName.c_str(), m_ValueParameterString.c_str());
	} else {
		action.SetAttribute(m_ValueParameterName.c_str(), m_ValueParameterDouble);
	}
}
