/*
   RuleSet.java

   eJS Project
     Kochi University of Technology
     the University of Electro-communications

     Tomoharu Ugawa, 2016-18
     Hideya Iwasaki, 2016-18
 */
package dispatch;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import type.VMDataType;


public class RuleSet {
    public static class OperandDataTypes {
        public VMDataType[] dts;

        OperandDataTypes(String tn1) {
            dts = new VMDataType[]{VMDataType.get(tn1)};
        }
        OperandDataTypes(String tn1, String tn2) {
            dts = new VMDataType[]{VMDataType.get(tn1), VMDataType.get(tn2)};
        }
        OperandDataTypes(VMDataType[] dts) {
            this.dts = dts;
        }
        @Override
        public int hashCode() {
            return Arrays.hashCode(dts);
        }
        @Override
        public boolean equals(Object obj) {
            if (obj != null && obj instanceof OperandDataTypes)
                return Arrays.equals(dts, ((OperandDataTypes) obj).dts);
            else
                return false;
        }
    };

    public static class Rule {
        public Set<OperandDataTypes> condition;
        public String action;

        Rule(String action, OperandDataTypes...  condition) {
            this.action = action;
            this.condition = new HashSet<OperandDataTypes>();
            for (OperandDataTypes c: condition)
                this.condition.add(c);
        }

        Rule(String action, List<OperandDataTypes> condition) {
            this.action = action;
            this.condition = new HashSet<OperandDataTypes>();
            for (OperandDataTypes c: condition)
                this.condition.add(c);
        }

        Rule(String action, Set<OperandDataTypes> condition) {
            this.action = action;
            this.condition = condition;
        }

        Rule filterConditions(Collection<OperandDataTypes> remove) {
            Set<OperandDataTypes> filteredCondition = new HashSet<RuleSet.OperandDataTypes>();
            for (OperandDataTypes c: condition)
                if (!remove.contains(c))
                    filteredCondition.add(c);
            return new Rule(action, filteredCondition);
        }

        public Set<OperandDataTypes> getCondition() {
            return condition;
        }
    }

    private String[] dispatchVars;
    Set<Rule> rules;

    public Set<Rule> getRules() {
        return rules;
    }
    public int getArity() {
        return dispatchVars.length;
    }

    RuleSet(String[] dispatchVars, Set<Rule> rules) {
        this.dispatchVars = dispatchVars;
        this.rules = rules;
    }
    public String[] getDispatchVars() {
        return dispatchVars;
    }
    public void setDispatchVars(String[] dispatchVars) {
        this.dispatchVars = dispatchVars;
    }
}
