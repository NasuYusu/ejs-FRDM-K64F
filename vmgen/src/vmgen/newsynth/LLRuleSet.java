/*
 * eJS Project
 * Kochi University of Technology
 * The University of Electro-communications
 *
 * The eJS Project is the successor of the SSJS Project at The University of
 * Electro-communications.
 */
package vmgen.newsynth;

import java.util.ArrayList;

import vmgen.RuleSet;
import vmgen.type.VMDataType;
import vmgen.type.VMRepType;

public class LLRuleSet {
    static final boolean DEBUG = true;

    static class LLRule {
        VMRepType[] rts;
        RuleSet.Rule hlr;

        LLRule(VMRepType[] rts, RuleSet.Rule hlr) {
            this.rts = rts;
            this.hlr = hlr;
        }

        public RuleSet.Rule getHLRule() {
            return hlr;
        }

        public VMRepType[] getVMRepTypes() {
            return rts;
        }
    }

    ArrayList<LLRule> rules = new ArrayList<LLRule>();

    public LLRuleSet(RuleSet hlrs) {
        for (RuleSet.Rule hr: hlrs.getRules())
            addFromHLRule(hr);
    }

    void addFromHLRule(RuleSet.Rule hlr) {
        for (RuleSet.Condition c: hlr.getCondition()) {
            VMRepType[] rts = new VMRepType[c.dts.length];
            enumAndAddVmRepTypeCombo(c.dts, rts, 0, hlr);
        }
    }

    void enumAndAddVmRepTypeCombo(VMDataType[] dts, VMRepType[] rts, int opOrder, RuleSet.Rule hlr) {
        if (opOrder == dts.length) {
            LLRule llr = new LLRule(rts.clone(), hlr);
            if (DEBUG) {
                if (rules.indexOf(llr) != -1)
                    throw new Error("LL-Rule duplicate");
            }
            rules.add(llr);
            return;
        }
        VMDataType dt = dts[opOrder];
        for (VMRepType rt: dt.getVMRepTypes()) {
            rts[opOrder] = rt;
            enumAndAddVmRepTypeCombo(dts, rts, opOrder + 1, hlr);
        }
    }

    public ArrayList<LLRule> getRules() {
        return rules;
    }
}
