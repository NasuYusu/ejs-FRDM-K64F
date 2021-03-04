/*
 * eJS Project
 * Kochi University of Technology
 * The University of Electro-communications
 *
 * The eJS Project is the successor of the SSJS Project at The University of
 * Electro-communications.
 */
package ejsc;

import java.io.FileOutputStream;

import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.HashSet;

import java.nio.ByteBuffer;

import ejsc.CodeBuffer.SpecialValue;
import specfile.SpecFile;

public class OBCFileComposer extends OutputFileComposer {
    static final boolean DEBUG = false;

    static final boolean BIG_ENDIAN = true;

    static final byte OBC_FILE_MAGIC = (byte) 0xec;

    static class OBCInstruction {
        enum Format {
            ABC,
            AB
        }

        static OBCInstruction createAB(String insnName, int opcode, int a, int b) {
            return new OBCInstruction(insnName, opcode, Format.AB, a, b, 0);
        }

        static OBCInstruction createABC(String insnName, int opcode, int a, int b, int c) {
            return new OBCInstruction(insnName, opcode, Format.ABC, a, b, c);
        }

        String insnName;  /* debug */
        int opcode;
        Format format;
        int a, b, c;

        OBCInstruction(String insnName, int opcode, Format format, int a, int b, int c) {
            this.insnName = insnName;
            this.opcode = opcode;
            this.format = format;
            this.a = a;
            this.b = b;
            this.c = c;
        }

        /**
         * Returns binary representation of the instruction.
         * 
         * @return binary representation of this instruction.
         */
        byte[] getBytes(InstructionBinaryFormat f) {
            long insn = ((long) opcode) << f.opcodeOffset();
            switch (format) {
            case ABC:
                insn |= (((long) a) << f.aOffset()) & f.aMask();
                insn |= (((long) b) << f.bOffset()) & f.bMask();
                insn |= (((long) c) << f.cOffset()) & f.cMask();
                break;
            case AB:
                insn |= (((long) a) << f.aOffset()) & f.aMask();
                insn |= (((long) b) << f.bbOffset()) & f.bbMask();
                break;
            default:
                throw new Error("Unknown instruction format");
            }

            if (DEBUG)
                System.out.print("insn: ");
            if (BIG_ENDIAN) {
                insn = Long.reverseBytes(insn);
                insn >>>= 8 * (8 - f.instructionBytes());
            }
            byte[] bytes = new byte[f.instructionBytes()];
            for (int i = 0; i < f.instructionBytes(); i++) {
                bytes[i] = (byte) (insn >> (8 * i));
                if (DEBUG)
                System.out.print(String.format(" %02x", bytes[i]));
            }
            if (DEBUG)
                System.out.println(String.format(" %s", insnName));
            return bytes;
        }
    }

    class OBCFunction implements CodeBuffer {
        int functionNumberOffset;

        /* function header */
        int callEntry;
        int sendEntry;
        int numberOfLocals;

        ConstantTable constants;
        List<OBCInstruction> instructions;

        OBCFunction(BCBuilder.FunctionBCBuilder fb, int functionNumberOffset) {
            this.functionNumberOffset = functionNumberOffset;

            List<BCode> bcodes = fb.getInstructions();
            this.callEntry = fb.callEntry.dist(0);
            this.sendEntry = fb.sendEntry.dist(0);
            this.numberOfLocals = fb.numberOfLocals;

            constants = new ConstantTable();
            instructions = new ArrayList<OBCInstruction>(bcodes.size());
            for (BCode bc : bcodes)
                bc.emit(this);
        }

        int getOpcode(String insnName, SrcOperand... srcs) {
            String decorated = OBCFileComposer.decorateInsnName(insnName, srcs);
            if (decorated == null)
                return spec.getOpcodeIndex(insnName);
            else
                return spec.getOpcodeIndex(decorated);
        }

        int fieldBitsOf(SrcOperand src) {
            if (src instanceof RegisterOperand) {
                Register r = ((RegisterOperand) src).get();
                int n = r.getRegisterNumber();
                return n;
            } else if (src instanceof FixnumOperand) {
                int n = ((FixnumOperand) src).get();
                return n;
            } else if (src instanceof FlonumOperand) {
                double n = ((FlonumOperand) src).get();
                int index = constants.lookup(n);
                return index;
            } else if (src instanceof StringOperand) {
                String s = ((StringOperand) src).get();
                int index = constants.lookup(s);
                return index;
            } else if (src instanceof SpecialOperand) {
                SpecialValue v = ((SpecialOperand) src).get();
                return format.specialFieldValue(v);
            } else
                throw new Error("Unknown source operand");
        }

        @Override
        public void addFixnumSmallPrimitive(String insnName, boolean log, Register dst, int n) {
            if (format.inFixnumRange(n)) {
                int opcode = getOpcode(insnName);
                int a = dst.getRegisterNumber();
                int b = n;
                OBCInstruction insn = OBCInstruction.createAB(insnName, opcode, a, b);
                instructions.add(insn);
            } else
                addNumberBigPrimitive("number", log, dst, (double) n);  // TODO: do not use "number"
        }
        @Override
        public void addNumberBigPrimitive(String insnName, boolean log, Register dst, double n) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            int b = constants.lookup(n);
            OBCInstruction insn = OBCInstruction.createAB(insnName, opcode, a, b);
            instructions.add(insn);

        }
        @Override
        public void addStringBigPrimitive(String insnName, boolean log, Register dst, String s) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            int b = constants.lookup(s);
            OBCInstruction insn = OBCInstruction.createAB(insnName, opcode, a, b);
            instructions.add(insn);
        }
        @Override
        public void addSpecialSmallPrimitive(String insnName, boolean log, Register dst, SpecialValue v) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            int b = format.specialFieldValue(v);
            OBCInstruction insn = OBCInstruction.createAB(insnName, opcode, a, b);
            instructions.add(insn);
        }
        @Override
        public void addRegexp(String insnName, boolean log, Register dst, int flag, String ptn) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            int c = constants.lookup(ptn);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, flag, c);
            instructions.add(insn);
        }
        @Override
        public void addRXXThreeOp(String insnName, boolean log, Register dst, SrcOperand src1, SrcOperand src2) {
            int opcode = getOpcode(insnName, src1, src2);
            int a = dst.getRegisterNumber();
            int b = fieldBitsOf(src1);
            int c = fieldBitsOf(src2);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, b, c);
            instructions.add(insn);
        }
        @Override
        public void addXXXThreeOp(String insnName, boolean log, SrcOperand src1, SrcOperand src2, SrcOperand src3) {
            int opcode = getOpcode(insnName, src1, src2, src3);
            int a = fieldBitsOf(src1);
            int b = fieldBitsOf(src2);
            int c = fieldBitsOf(src3);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, b, c);
            instructions.add(insn);
        }
        @Override
        public void addXIXThreeOp(String insnName, boolean log, SrcOperand src1, int index, SrcOperand src2) {
            int opcode = getOpcode(insnName, src1, src2);
            int a = fieldBitsOf(src1);
            int c = fieldBitsOf(src2);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, index, c);
            instructions.add(insn);
        }
        @Override
        public void addRXTwoOp(String insnName, boolean log, Register dst, SrcOperand src) {
            int opcode = getOpcode(insnName, src);
            int a = dst.getRegisterNumber();
            int b = fieldBitsOf(src);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, b, 0);
            instructions.add(insn);
        }
        @Override
        public void addXXTwoOp(String insnName, boolean log, SrcOperand src1, SrcOperand src2) {
            int opcode = getOpcode(insnName, src1, src2);
            int a = fieldBitsOf(src1);
            int b = fieldBitsOf(src2);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, b, 0);
            instructions.add(insn);
        }
        @Override
        public void addROneOp(String insnName, boolean log, Register dst) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, 0, 0);
            instructions.add(insn);
        }
        @Override
        public void addXOneOp(String insnName, boolean log, SrcOperand src) {
            int opcode = getOpcode(insnName, src);
            int a = fieldBitsOf(src);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, 0, 0);
            instructions.add(insn);
        }
        @Override
        public void addIOneOp(String insnName, boolean log, int n) {
            int opcode = getOpcode(insnName);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, n, 0, 0);
            instructions.add(insn);
        }
        @Override
        public void addZeroOp(String insnName, boolean log) {
            int opcode = getOpcode(insnName);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, 0, 0, 0);
            instructions.add(insn);
        }
        @Override
        public void addNewFrameOp(String insnName, boolean log, int len, boolean mkargs) {
            int opcode = getOpcode(insnName);
            int b = mkargs ? 1 : 0;
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, len, b, 0);
            instructions.add(insn);
        }
        @Override
        public void addGetVar(String insnName, boolean log, Register dst, int link, int index) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, link, index);
            instructions.add(insn);
        }
        @Override
        public void addSetVar(String insnName, boolean log, int link, int index, SrcOperand src) {
            int opcode = getOpcode(insnName, src);
            int c = fieldBitsOf(src);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, link, index, c);
            instructions.add(insn);
        }
        @Override
        public void addMakeClosureOp(String insnName, boolean log, Register dst, int index) {
            int opcode = getOpcode(insnName);
            int a = dst.getRegisterNumber();
            // int b = index + functionNumberOffset;
            int b = index;
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, b, 0);
            instructions.add(insn);
        }
        @Override
        public void addXICall(String insnName, boolean log, SrcOperand fun, int nargs) {
            int opcode = getOpcode(insnName, fun);
            int a = fieldBitsOf(fun);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, nargs, 0);
            instructions.add(insn);
        }
        @Override
        public void addRXCall(String insnName, boolean log, Register dst, SrcOperand fun) {
            int opcode = getOpcode(insnName, fun);
            int a = dst.getRegisterNumber();
            int b = fieldBitsOf(fun);
            OBCInstruction insn = OBCInstruction.createABC(insnName, opcode, a, b, 0);
            instructions.add(insn);
        }
        @Override
        public void addUncondJump(String insnName, boolean log, int disp) {
            int opcode = getOpcode(insnName);
            OBCInstruction insn = OBCInstruction.createAB(insnName, opcode, 0, disp);
            instructions.add(insn);
        }
        @Override
        public void addCondJump(String insnName, boolean log, SrcOperand test, int disp) {
            int opcode = getOpcode(insnName, test);
            int a = fieldBitsOf(test);
            OBCInstruction insn = OBCInstruction.createAB(insnName, opcode, a, disp);
            instructions.add(insn);
        }
    }

    List<OBCFunction> obcFunctions;

    OBCFileComposer(BCBuilder compiledFunctions, int functionNumberOffset, SpecFile spec, boolean insn32, boolean align32) {
        super(spec, insn32, align32);
        List<BCBuilder.FunctionBCBuilder> fbs = compiledFunctions.getFunctionBCBuilders();
        obcFunctions = new ArrayList<OBCFunction>(fbs.size());
        for (BCBuilder.FunctionBCBuilder fb : fbs) {
            OBCFunction out = new OBCFunction(fb, functionNumberOffset);
            obcFunctions.add(out);
        }
    }

    private void outputByte(OutputStream out, byte v) throws IOException {
        if (DEBUG)
            System.out.println(String.format("byte: %02x", v));
        out.write(v);
    }

    private void outputShort(OutputStream out, int v) throws IOException {
        if (DEBUG)
            System.out.println(String.format("short: %04x", v));
        if (BIG_ENDIAN)
            v = Integer.reverseBytes(v << 16);
        out.write((byte) (v & 0xff));
        out.write((byte) ((v >> 8) & 0xff));
    }

    private void outputLong(OutputStream out, long v) throws IOException {
        if (DEBUG)
            System.out.println(String.format("short: %016x", v));
        if (BIG_ENDIAN)
            v = Long.reverseBytes(v);
        for (int i = 0; i < 8; i++)
            out.write((byte) ((v >> (8 * i)) & 0xff));
    }
    private int update_hash(int hash, String s) {
        for (int i = 0; i < s.length(); i++) {
            hash += (int)s.charAt(i);
            hash += (hash << 10);
            hash ^= hash >>> 6;
        }
        return hash;
    }

    private int finalise_hash(int hash) {
        hash += hash << 3;
        hash ^= hash >>> 11;
        hash += hash << 15;
        return hash;
    }

    private int word_size(int size) {
        int word;
        word = ((byte)size + (1 << 2) - 1) >>> 2;
        return word;
    }

    public static byte[] int_to_bytes(int value) {
        ByteBuffer buffer = ByteBuffer.allocate(4);
        buffer.putInt(value);
        return buffer.array();
    }

    public void print_byte(List<String> list) {
        String str_name;
        int hash, length, word;
        byte[] words, hash_byte, len, bytes;
        for (int i = 0; i < list.size(); i++) {
            System.out.print("const char preload_string_" + i + "[] = {");
            str_name = (String)list.get(i);
            length = str_name.length();
            hash = update_hash(0, str_name);
            hash = finalise_hash(hash);
            word = word_size(8 + length + 1) + 2; // 4byte * 2 + len + 1

            // header
            System.out.print("0x04, 0x00, 0x00, 0x00, "); // type instruction (String = 4)
            words = int_to_bytes(word); // 1word
            for (int j = (words.length - 1); j > -1; j--) {
                System.out.print(String.format("0x%02x, ", words[j]));
            }

            // hash
            hash_byte = int_to_bytes(hash);
            for (int j = (hash_byte.length - 1); j > -1; j--) {
                System.out.print(String.format("0x%02x, ", hash_byte[j]));
            }

            // length
            len = int_to_bytes(length);
            for (int j = (len.length - 1); j > -1; j--) {
                System.out.print(String.format("0x%02x, ", len[j]));
            }

            // value
            bytes = str_name.getBytes();
            for (int j = 0; j < length; j++) System.out.print(String.format("0x%01x, ", bytes[j]));
                System.out.print("0x00");
                System.out.println("};");
        }
        System.out.println("const char* const preload_strings[] = {");
        for (int i = 0; i < list.size(); i++) {
            System.out.print(" preload_string_" + i);
            if (i < (list.size() - 1)) System.out.println(",");
            else System.out.println();
        }
        System.out.println("};");
    }

    /**
     * Output instruction to the file.
     * 
     * @param fileName
     *            file name to be output to.
     */
    void output(String fileName) {
        HashSet<String> strings = new HashSet<String>();
        try {
            FileOutputStream out = new FileOutputStream(fileName);

            outputByte(out, OBC_FILE_MAGIC);
            outputByte(out, spec.getFingerprint());

            /* File header */
            outputShort(out, obcFunctions.size());

            /* Function */
            for (OBCFunction fun : obcFunctions) {
                /* Function header */
                outputShort(out, fun.callEntry);
                outputShort(out, fun.sendEntry);
                outputShort(out, fun.numberOfLocals);
                outputShort(out, fun.instructions.size());
                outputShort(out, fun.constants.size());

                /* Instructions */
                for (OBCInstruction insn : fun.instructions)
                    out.write(insn.getBytes(format));

                /* Constant pool */
                for (Object v : fun.constants.getConstants()) {
                    if (v instanceof Double) {
                        long bits = Double.doubleToLongBits((Double) v);
                        outputShort(out, 8); // size
                        outputLong(out, bits);
                    } else if (v instanceof String) {
                        String s = (String) v;
                        outputShort(out, s.length() + 1); // size
                        strings.add(s);
                        if (DEBUG)
                            System.out.println("string: "+s);
                        out.write(s.getBytes());
                        out.write('\0');
                    } else
                        throw new Error("Unknown constant");
                }
            }
            out.close();

            /* global constants */
            /*List<String> constantsList = Arrays.asList("", "apply", "abs", "address", "PI", "boolean", "now", "pow", "printv", "Number", "debugarray", "false", 
            "toString", "__property_map__", "log", "String", "push", "lastIndexOf", "charCodeAt", "random", "LN10", "pop",
             "null", "number", "E", "LOG2E", "toUpperCase", "atan2", "max", "toLowerCase", "shift", "Infinity", "sort", 
            "true", "Boolean", "tan", "Object", "isFinite", "INFINITY", "SQRT2", "concat", "to_number", "acos", "NaN", 
            "sqrt", "printStatus", "localeCompare", "hello", "substring", "SQRT1_2", "prototype", "LN2", "join", "string", 
            ",", "atan", "MIN_VALUE", "floor", "NEGATIVE_INFINITY", "undefined", "slice", "valueOf", "Array", 
            "fromCharCode", "indexOf", "length", "LOG10E", "Function", "round", "MAX_VALUE", "parseFloat", "charAt", "exp",
             "cos", "reverse", "isNaN", "print", "to_string", "toLocaleString", "asin", "parseInt", "sin", "__proto__", 
            "Math", " ", "object", "min", "ceil", "[object Object]", "performance");*/
            //print_byte(constantsList);

            List<String> stringList = new ArrayList<>(strings);
            print_byte(stringList);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
}
