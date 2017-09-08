import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

class LLRule {
	static class Condition {
		VMRepType[] trs;

		int arity;
		boolean done;

		Condition(VMRepType... rts) {
			this.trs = rts;
			arity = rts.length;
			done = false;
		}
		
		/**
		 * Create a tuple of VMRepType from the given tuple of VMDataType.
		 * A VMDataType may have multiple VMRepType.  When VMDataType_i
		 * has n_i VMRepTypes, a tuple of VMDataType (VMDataType_0, ..., VM_DataType_{m-1})
		 * has n_0 * ... * n_{m-1} tuples of VMRepTypes.
		 * @param dts tuple of VMDataType (high-level condition)
		 * @param index This constructor creates index-th tuple of VMRepType
		 */
		Condition(VMDataType[] dts, int index) {
			arity = dts.length;
			trs = new VMRepType[arity];
			for (int i = 0; i < arity; i++) {
				List<VMRepType> vmRepTypes = dts[i].getVMRepTypes();
				int base = vmRepTypes.size();
				trs[i] = vmRepTypes.get(index % base);
				index /= base;
			}
			done = false;
		}
	}

	Set<Condition> condition;
	DDNode action;

	LLRule(Set<Condition> condition, DDNode action) {
		this.condition = condition;
		this.action = action;
	}

	LLRule(Condition condition, DDNode action) {
		this.condition = new HashSet<Condition>();
		this.condition.add(condition);
		this.action = action;
	}

	/**
	 * Creates LLRule from (high level) Rule
	 * @param r (high level) Rule
	 */
	LLRule(Plan.Rule r) {
		condition = new HashSet<Condition>();
		for (Plan.Condition dtc: r.condition) {
			int nRtc = 1;
			for (VMDataType dt: dtc.dts)
				nRtc *= dt.getVMRepTypes().size();
			for (int i = 0; i < nRtc; i++)
				condition.add(new Condition(dtc.dts, i));
		}
		action = new DDLeaf(r);
	}


	public Condition find(VMRepType... key) {
		NEXT_CONDITION: for (Condition c: condition) {
			if (c.arity != key.length)
				continue;
			for (int i = 0; i < c.arity; i++) {
				if (! c.trs[i].equals(key[i]))
				 continue NEXT_CONDITION;
			}
			return c;
		}
		return null;
	}

	@Override
	public String toString() {
		return "[{" +
				condition.stream().map(c -> {
					return (c.done ? "-" : "") +
						Arrays.stream(c.trs)
							.map(tr -> tr.name)
							.collect(Collectors.joining("*"));
				}).collect(Collectors.joining(", "))
				+ "} -> " + action.toString() + "]";
	}
}

public class LLPlan {
	String[] dispatchVars;
	Set<LLRule> rules;

	LLPlan(Plan plan) {
		dispatchVars = plan.dispatchVars;
		rules = plan.getRules().stream()
				.map(r -> new LLRule(r))
				.collect(Collectors.toSet());
	}

	LLPlan(String[] dispatchVars) {
		this.dispatchVars = dispatchVars;
		rules = new HashSet<LLRule>();
	}

	/**
	 * Enumerates all PTs appearing in the n-th operands of all rules.
	 * @param n
	 * @return Set of PTs
	 */
	public Set<PT> allPTNthOperand(int n) {
		Set<PT> pts = new HashSet<PT>();
		for (LLRule r: rules) {
			for (LLRule.Condition c: r.condition)
				pts.add(c.trs[0].getPT());
		}
		return pts;
	}

	public Set<VMRepType> allTRNthOperand(int n) {
		Set<VMRepType> trs = new HashSet<VMRepType>();
		for (LLRule r: rules) {
			for (LLRule.Condition c: r.condition)
				trs.add(c.trs[0]);
		}
		return trs;
	}

	/**
	 * Find the low level rule that matches the given condition.
	 */
	public LLRule find(VMRepType... key) {
		for (LLRule r: rules) {
			if (r.find(key) != null)
				return r;
		}
		return null;
	}

	/**
	 * Find the low level rule that matches the given condition.
	 */
	public Set<LLRule> findByPT(PT... key) {
		Set<LLRule> result = new HashSet<LLRule>();
		NEXT_RULE: for (LLRule r: rules) {
			NEXT_CONDITION: for (LLRule.Condition c: r.condition) {
				if (c.arity != key.length)
					continue;
				for (int i = 0; i < c.arity; i++) {
					if (c.trs[i].getPT() != key[i])
						continue NEXT_CONDITION;
				}
				result.add(r);
				continue NEXT_RULE;
			}
		}
		return result;
	}

	/**
	 * Convert this tuple-dispatch plan to a nested single-dispatch plan.
	 * @param redirect if true, create redirect actions
	 * @return nested plan
	 */
	public LLPlan convertToNestedPlan(boolean redirect, VMRepType[] dispatchVals) {
		int level = dispatchVals.length;
		LLPlan outer = new LLPlan(new String[] {dispatchVars[level]});
		for (VMRepType tr: allTRNthOperand(level)) {
			VMRepType[] nextVals = new VMRepType[level + 1];
			System.arraycopy(dispatchVals, 0, nextVals, 0, level);
			nextVals[level] = tr;
			if (nextVals.length == dispatchVars.length) {
				LLRule r = find(nextVals);
				LLRule.Condition c = new LLRule.Condition(tr);
				c.done = r.find(nextVals).done;
				LLRule newRule = new LLRule(c, r.action);
				outer.rules.add(newRule);
			} else {
				LLPlan inner = convertToNestedPlan(redirect, nextVals);
				LLRule.Condition outerCond = new LLRule.Condition(tr);
				outerCond.done = inner.rules.stream()
						.flatMap(r -> r.condition.stream())
						.allMatch(c -> c.done);
				DDUnexpandedNode outerAction = new DDUnexpandedNode(inner);
				LLRule outerRule = new LLRule(outerCond, outerAction);
				outer.rules.add(outerRule);
			}
		}
		return outer;
	}

	public LLPlan convertToNestedPlan(boolean redirect) {
		return convertToNestedPlan(redirect, new VMRepType[]{});
	}

	protected boolean mergable(LLRule r0, LLRule r1) {
		if (!(r0.action instanceof DDUnexpandedNode))
			throw new Error("attempted to merge an ActionNode that is not an UnexpandedActionNode: "+ r0);
		if (!(r1.action instanceof DDUnexpandedNode))
			throw new Error("attempted to merge an ActionNode that is not an UnexpandedActionNode: "+ r1);
		LLPlan llplan0 = ((DDUnexpandedNode) r0.action).ruleList;
		LLPlan llplan1 = ((DDUnexpandedNode) r1.action).ruleList;

		for (LLRule innerRule0: llplan0.rules) {
			NEXT_C0: for (LLRule.Condition c0: innerRule0.condition) {
				for (LLRule innerRule1: llplan1.rules) {
					NEXT_C1: for (LLRule.Condition c1: innerRule1.condition) {
						if (c0.done && c1.done)
							continue NEXT_C0;
						for (int i = 0; i < c0.arity; i++) {
							if (!c0.trs[i].equals(c1.trs[i]))
								continue NEXT_C1;
						}
						if (((DDRedirectNode) innerRule0.action).destination ==
							((DDRedirectNode) innerRule1.action).destination)
							continue NEXT_C0;
						return false;
					}
				}
				return false;
			}
		}
		return true;
	}

	/**
	 * Convert itself to its canonical form.
	 * 1. Canonical form has no rules all of whose conditions has been "done".
	 * 2. All actions of canonical form are distinct.  (Rules that has the same
	 *    action are merged.)
	 * 3. All inner plans are in canonical form.
	 */
	public void canonicalise() {
		Set<LLRule> result = new HashSet<LLRule>();

		rules.stream()
		.filter(r -> r.condition.stream().anyMatch(c -> !c.done))
		.map(r -> {
			Set<LLRule.Condition> cond = r.condition.stream().filter(c -> !c.done).collect(Collectors.toSet());
			return new LLRule(cond, r.action);
		})
		.forEach(r -> {
			for (LLRule newr: result)
				if (newr.action.mergable(r.action)) {
					newr.condition.addAll(r.condition);
					return;
				}
			result.add(r);
		});
		result.forEach(r -> {
			if (r.action instanceof DDUnexpandedNode)
				((DDUnexpandedNode) r.action).ruleList.canonicalise();
		});
		rules = result;
	}

	@Override
	public String toString() {
		return rules.stream().map(dr -> dr.toString()).collect(Collectors.joining("\n"));
	}
}