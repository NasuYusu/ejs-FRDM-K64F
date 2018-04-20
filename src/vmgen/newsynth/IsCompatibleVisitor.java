package vmgen.newsynth;

import java.util.ArrayList;
import java.util.LinkedHashSet;

import vmgen.newsynth.DecisionDiagram.HTNode;
import vmgen.newsynth.DecisionDiagram.Leaf;
import vmgen.newsynth.DecisionDiagram.Node;
import vmgen.newsynth.DecisionDiagram.TagNode;

class IsCompatibleVisitor extends NodeVisitor {
	Node root;
	Node currentNodex;
	
	IsCompatibleVisitor(Node root) {
		this.root = root;
		currentNodex = root;
	}
	
	<T> boolean hasCompatibleBranches(TagNode<T> currentNode, TagNode<T> other) {
		LinkedHashSet<T> union = new LinkedHashSet<T>(currentNode.branches.keySet());
		union.addAll(other.branches.keySet());
		for (T tag: union) {
			Node thisChild = currentNode.branches.get(tag);
			Node otherChild = other.branches.get(tag);
			if (thisChild != null && otherChild != null) {
				currentNodex = thisChild;
				if (!(Boolean) otherChild.accept(this))
					return false;
			}
		}
		return true;
	}

	@Override
	Object visitLeaf(Leaf other) {
		if (currentNodex instanceof Leaf) {
			Leaf currentNode = (Leaf) currentNodex;
			for (int i = 0; i < lv; i++) System.out.print("  ");
			System.out.println("leaf--"+currentNode+" "+other);
			for (int i = 0; i < lv; i++) System.out.print("  ");
			if (currentNode.getRule().getHLRule() == other.getRule().getHLRule())
				System.out.println(true);
			else 
				System.out.println(false);

			if (currentNode.getRule().getHLRule() == other.getRule().getHLRule())
				return true;
			else 
				return false;
		}
		return false;
	}

	int lv = 0;
	@Override
	<T> Object visitTagNode(TagNode<T> other) {
		if (currentNodex.getClass() == other.getClass()) {
			TagNode<T> currentNode = (TagNode<T>) currentNodex;
			if (currentNode.getOpIndex() != other.getOpIndex())
				throw new Error("opIndex mismatch");
			
			if (true) {
				for (int i = 0; i < lv; i++) System.out.print("  ");
				System.out.println("hasCompatibleBranches--"+currentNode+" "+other);
				lv++;
				boolean ret = hasCompatibleBranches(currentNode, other);
				lv--;
				for (int i = 0; i < lv; i++) System.out.print("  ");
				System.out.println("==> "+ret);
				return ret;
			}				
			return hasCompatibleBranches(currentNode, other);
		}
		return false;
	}

	@Override
	Object visitHTNode(HTNode other) {
		if (currentNodex instanceof HTNode) {
			HTNode currentNode = (HTNode) currentNodex;
			if (currentNode.getOpIndex() != other.getOpIndex())
				throw new Error("opIndex mismatch");
			
			// if each node has a single child, they are compatible iff their children are compatible,
			// regardless of existence of HT.
			if (currentNode.isNoHT() && other.isNoHT()) {
				currentNodex = currentNode.getChild();
				return other.getChild().accept(this);
			} else if (currentNode.isNoHT()) {
				ArrayList<Node> otherChildren = other.getChildren();
				if (otherChildren.size() == 1) {
					currentNodex = currentNode.getChild();
					return otherChildren.get(0).accept(this);
				} else
					return false;
			} else if (other.isNoHT()) {
				ArrayList<Node> currentNodeChildren = currentNode.getChildren();
				if (currentNodeChildren.size() == 1) {
					currentNodex = currentNodeChildren.get(0);
					return other.getChild().accept(this);
				} else
					return false;
			} else {
				if (true) {
					for (int i = 0; i < lv; i++) System.out.print("  ");
					System.out.println("hasCompatibleBranches--"+currentNode+" "+other);
					lv++;
					boolean ret = hasCompatibleBranches(currentNode, other);
					lv--;
					for (int i = 0; i < lv; i++) System.out.print("  ");
					System.out.println("==> "+ret);
					return ret;
				}				
				return hasCompatibleBranches(currentNode, other);
			}
		}
		return false;
	}
}