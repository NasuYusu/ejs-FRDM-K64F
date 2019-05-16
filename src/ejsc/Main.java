/*
   Main.java

   eJS Project
     Kochi University of Technology
     the University of Electro-communications

     Takafumi Kataoka, 2017-18
     Tomoya Nonaka, 2018
     Tomoharu Ugawa, 2017-18
     Hideya Iwasaki, 2017-18

   The eJS Project is the successor of the SSJS Project at the University of
   Electro-communications, which was contributed by the following members.

     Sho Takada, 2012-13
     Akira Tanimura, 2012-13
     Akihiro Urushihara, 2013-14
     Ryota Fujii, 2013-14
     Tomoharu Ugawa, 2012-14
     Hideya Iwasaki, 2012-14
*/
package ejsc;
import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;

import ejsc.antlr.*;
import ejsc.ast_node.Node;

import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.util.List;
import java.util.LinkedList;


public class Main {

    static class Info {
        List<String> inputFileNames = new LinkedList<String>();   // .js
        List<Integer> loggedInputFileIndices = new LinkedList<Integer>();   // .js
        String outputFileName;  // .sbc
        enum OptLocals {
            NONE,
            PROSYM,
            G1,
            G3;
        }

        boolean optPrintESTree = false;
        boolean optPrintIAST = false;
        boolean optPrintAnalyzer = false;
        boolean optPrintLowLevelCode = false;
        boolean optPrintOptimisation = false;
        boolean optHelp = false;
        boolean optRedunantInstructionElimination = false;
        boolean optConstantPropagation = false;
        boolean optCopyPropagation = false;
        boolean optRegisterAssignment = false;
        boolean optCommonConstantElimination = false;
        boolean optEnableLogging = false;
        OptLocals optLocals = OptLocals.NONE;

        static Info parseOption(String[] args) {
            Info info = new Info();
            for (int i = 0; i < args.length; i++) {
                if (args[i].charAt(0) == '-') {
                    switch (args[i]) {
                    case "--estree":
                        info.optPrintESTree = true;
                        break;
                    case "--iast":
                        info.optPrintIAST = true;
                        break;
                    case "--analyzer":
                        info.optPrintAnalyzer = true;
                        break;
                    case "--show-llcode":
                        info.optPrintLowLevelCode = true;
                        break;
                    case "--show-opt":
                        info.optPrintOptimisation = true;
                        break;
                    case "--help":
                        info.optHelp = true;
                        break;
                    case "-o":
                        info.outputFileName = args[++i];
                        break;
                    case "-omit-arguments":
                        throw new Error("obsolete option: -omit-arguments");
                    case "-opt-prosym":
                    case "-omit-frame":
                        info.optLocals = OptLocals.PROSYM;
                        break;
                    case "-opt-g1":
                        info.optLocals = OptLocals.G1;
                        break;
                    case "-opt-g3":
                        info.optLocals = OptLocals.G3;
                        break;
                    case "-opt-const":
                        info.optConstantPropagation = true;
                        break;
                    case "-opt-rie":
                        info.optRedunantInstructionElimination = true;
                        break;
                    case "-opt-cce":
                        info.optCommonConstantElimination = true;
                        break;
                    case "-opt-copy":
                        info.optCopyPropagation = true;
                        break;
                    case "-opt-reg":
                        info.optRegisterAssignment = true;
                        break;
                    case "-log":
                        i++;
                        if (i >= args.length) {
                            throw new Error("failed to parse arguments: -log");
                        }
                        info.loggedInputFileIndices.add(info.inputFileNames.size());
                        info.inputFileNames.add(args[i]);
                        info.optEnableLogging = true;
                        break;
                    default:
                        throw new Error("unknown option: "+args[i]);
                    }
                } else {
                    info.inputFileNames.add(args[i]);
                }
            }
            if (info.inputFileNames.size() == 0) {
                info.optHelp = true;
            } else if (info.outputFileName == null) {
                String firstInputFileName = info.inputFileNames.get(0);
                int pos = firstInputFileName.lastIndexOf(".");
                if (pos != -1) {
                    info.outputFileName = firstInputFileName.substring(0, pos) + ".sbc";
                } else {
                    info.outputFileName = firstInputFileName + ".sbc";
                }
            }
            return info;
        }
    }

    void writeBCodeToSBCFile(List<BCode> bcodes, String filename) {
        try {
            File file = new File(filename);
            PrintWriter pw = new PrintWriter(new BufferedWriter(new FileWriter(file)));
            for (BCode bc : bcodes) {
                pw.println(bc.toString());
            }
            pw.close();
        } catch(IOException e) {
            System.out.println(e);
        }
    }

    void run(String[] args) {

        // Parse command line option.
        Info info = Info.parseOption(args);
        if (info.optHelp && info.inputFileNames.size() == 0) {
            // TODO print how to use ...
            return;
        }


        IASTProgram iast = new IASTProgram();
        for (int i = 0; i < info.inputFileNames.size(); i++) {
            String fname = info.inputFileNames.get(i);
            // Parse JavaScript File
            ANTLRInputStream antlrInStream;
            try {
                InputStream inStream;
                inStream = new FileInputStream(fname);
                antlrInStream = new ANTLRInputStream(inStream);
            } catch (IOException e) {
                System.out.println(e);
                return;
            }
            ECMAScriptLexer lexer = new ECMAScriptLexer(antlrInStream);
            CommonTokenStream tokens = new CommonTokenStream(lexer);
            ECMAScriptParser parser = new ECMAScriptParser(tokens);
            ParseTree tree = parser.program();

            // convert ANTLR's parse tree into ESTree.
            ASTGenerator astgen = new ASTGenerator(info.loggedInputFileIndices.contains(i));
            Node ast = astgen.visit(tree);

            if (info.optPrintESTree) {
                System.out.println(ast.getEsTree());
            }

            // normalize ESTree.
            new ESTreeNormalizer().normalize(ast);
            //            if (info.optPrintESTree) {
            //                System.out.println(ast.getEsTree());
            //            }

            // convert ESTree into iAST.
            IASTGenerator iastgen = new IASTGenerator();
            IASTFunctionExpression iastFile = iastgen.gen(ast);
            iast.add(iastFile);
        }


        if (info.optPrintIAST) {
            new IASTPrinter().print(iast);
        }

        // iAST level optimisation
        if (info.optLocals != Info.OptLocals.NONE) {
            // iAST newargs analyzer
            NewargsAnalyzer analyzer = new NewargsAnalyzer(info.optLocals);
            analyzer.analyze(iast);
            if (info.optPrintAnalyzer) {
                new IASTPrinter().print(iast);
            }
        }

        // convert iAST into low level code.
        CodeGenerator codegen = new CodeGenerator(info.optLocals, info.optEnableLogging);
        BCBuilder bcBuilder = codegen.compile((IASTProgram) iast);

        bcBuilder.optimisation(info);

        if (info.optPrintLowLevelCode) {
            bcBuilder.assignAddress();
            System.out.print(bcBuilder);
        }

        // macro instruction expansion
        bcBuilder.expandMacro();

        // resolve jump destinations
        bcBuilder.assignAddress();

        // replace instructions for logging
        bcBuilder.replaceInstructionsForLogging();

        if (info.optPrintLowLevelCode) {
            bcBuilder.assignAddress();
            System.out.print(bcBuilder);
        }

        List<BCode> bcodes = bcBuilder.build();

        writeBCodeToSBCFile(bcodes, info.outputFileName);
    }

    public static void main(String[] args) throws IOException {
        new Main().run(args);
    }
}
