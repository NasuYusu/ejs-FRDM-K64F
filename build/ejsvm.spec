%% instruction def
fixnum SMALLPRIMITIVE Register int
specconst SMALLPRIMITIVE Register int
string BIGPRIMITIVE LABELONLY
regexp BIGPRIMITIVE LABELONLY
number BIGPRIMITIVE Register ConstantDisplacement
add THREEOP Register JSValue JSValue
sub THREEOP Register JSValue JSValue
mul THREEOP Register JSValue JSValue
div THREEOP Register JSValue JSValue
mod THREEOP Register JSValue JSValue
bitand THREEOP Register JSValue JSValue
bitor THREEOP Register JSValue JSValue
leftshift THREEOP Register JSValue JSValue
rightshift THREEOP Register JSValue JSValue
unsignedrightshift THREEOP Register JSValue JSValue
lessthan THREEOP Register JSValue JSValue
lessthanequal THREEOP Register JSValue JSValue
eq THREEOP Register JSValue JSValue
equal THREEOP Register JSValue JSValue
getarg THREEOP Register int Subscript
setarg THREEOP int Subscript JSValue
getprop THREEOP Register JSValue JSValue
setprop THREEOP JSValue JSValue JSValue
getglobal TWOOP Register JSValue
setglobal TWOOP JSValue JSValue
instanceof THREEOP Register JSValue JSValue
move TWOOP Register JSValue
typeof TWOOP Register Register
not TWOOP Register JSValue
new TWOOP Register JSValue
isundef TWOOP Register JSValue
isobject TWOOP Register JSValue
setfl ONEOP int
seta ONEOP JSValue
geta ONEOP Register
geterr ONEOP Register
getglobalobj ONEOP Register
newframe TWOOP int int
exitframe ZEROOP
ret ZEROOP
nop ZEROOP
jump UNCONDJUMP InstructionDisplacement
jumptrue CONDJUMP JSValue InstructionDisplacement
jumpfalse CONDJUMP JSValue InstructionDisplacement
getlocal GETVAR Register int Subscript
setlocal SETVAR int Subscript JSValue
makeclosure MAKECLOSUREOP Register Subscript
makeiterator TWOOP Register JSValue
nextpropnameidx TWOOP Register JSValue
send CALLOP LABELONLY
newsend CALLOP LABELONLY
call CALLOP JSValue int
tailsend CALLOP LABELONLY
tailcall CALLOP JSValue int
pushhandler UNCONDJUMP InstructionDisplacement
pophandler ZEROOP
throw ONEOP JSValue
localcall UNCONDJUMP InstructionDisplacement
localret ZEROOP
poplocal ZEROOP
error BIGPRIMITIVE Register ConstantDisplacement
unknown UNKNOWNOP
end ZEROOP
%% superinstruction spec
add(-,_,fixnum): addregfix
add(-,_,flonum): addregflo
add(-,_,string): addregstr
add(-,_,special): addregspec
add(-,fixnum,_): addfixreg
add(-,fixnum,flonum): addfixflo
add(-,fixnum,string): addfixstr
add(-,fixnum,special): addfixspec
add(-,flonum,_): addfloreg
add(-,flonum,fixnum): addflofix
add(-,flonum,string): addflostr
add(-,flonum,special): addflospec
add(-,string,_): addstrreg
add(-,string,fixnum): addstrfix
add(-,string,flonum): addstrflo
add(-,string,special): addstrspec
add(-,special,_): addspecreg
add(-,special,fixnum): addspecfix
add(-,special,flonum): addspecflo
add(-,special,string): addspecstr
bitand(-,_,fixnum): bitandregfix
bitand(-,_,flonum): bitandregflo
bitand(-,_,string): bitandregstr
bitand(-,_,special): bitandregspec
bitand(-,fixnum,_): bitandfixreg
bitand(-,fixnum,flonum): bitandfixflo
bitand(-,fixnum,string): bitandfixstr
bitand(-,fixnum,special): bitandfixspec
bitand(-,flonum,_): bitandfloreg
bitand(-,flonum,fixnum): bitandflofix
bitand(-,flonum,string): bitandflostr
bitand(-,flonum,special): bitandflospec
bitand(-,string,_): bitandstrreg
bitand(-,string,fixnum): bitandstrfix
bitand(-,string,flonum): bitandstrflo
bitand(-,string,special): bitandstrspec
bitand(-,special,_): bitandspecreg
bitand(-,special,fixnum): bitandspecfix
bitand(-,special,flonum): bitandspecflo
bitand(-,special,string): bitandspecstr
bitor(-,_,fixnum): bitorregfix
bitor(-,_,flonum): bitorregflo
bitor(-,_,string): bitorregstr
bitor(-,_,special): bitorregspec
bitor(-,fixnum,_): bitorfixreg
bitor(-,fixnum,flonum): bitorfixflo
bitor(-,fixnum,string): bitorfixstr
bitor(-,fixnum,special): bitorfixspec
bitor(-,flonum,_): bitorfloreg
bitor(-,flonum,fixnum): bitorflofix
bitor(-,flonum,string): bitorflostr
bitor(-,flonum,special): bitorflospec
bitor(-,string,_): bitorstrreg
bitor(-,string,fixnum): bitorstrfix
bitor(-,string,flonum): bitorstrflo
bitor(-,string,special): bitorstrspec
bitor(-,special,_): bitorspecreg
bitor(-,special,fixnum): bitorspecfix
bitor(-,special,flonum): bitorspecflo
bitor(-,special,string): bitorspecstr
div(-,_,fixnum): divregfix
div(-,_,flonum): divregflo
div(-,_,string): divregstr
div(-,_,special): divregspec
div(-,fixnum,_): divfixreg
div(-,fixnum,flonum): divfixflo
div(-,fixnum,string): divfixstr
div(-,fixnum,special): divfixspec
div(-,flonum,_): divfloreg
div(-,flonum,fixnum): divflofix
div(-,flonum,string): divflostr
div(-,flonum,special): divflospec
div(-,string,_): divstrreg
div(-,string,fixnum): divstrfix
div(-,string,flonum): divstrflo
div(-,string,special): divstrspec
div(-,special,_): divspecreg
div(-,special,fixnum): divspecfix
div(-,special,flonum): divspecflo
div(-,special,string): divspecstr
eq(-,_,fixnum): eqregfix
eq(-,_,flonum): eqregflo
eq(-,_,string): eqregstr
eq(-,_,special): eqregspec
eq(-,fixnum,_): eqfixreg
eq(-,fixnum,flonum): eqfixflo
eq(-,fixnum,string): eqfixstr
eq(-,fixnum,special): eqfixspec
eq(-,flonum,_): eqfloreg
eq(-,flonum,fixnum): eqflofix
eq(-,flonum,string): eqflostr
eq(-,flonum,special): eqflospec
eq(-,string,_): eqstrreg
eq(-,string,fixnum): eqstrfix
eq(-,string,flonum): eqstrflo
eq(-,string,special): eqstrspec
eq(-,special,_): eqspecreg
eq(-,special,fixnum): eqspecfix
eq(-,special,flonum): eqspecflo
eq(-,special,string): eqspecstr
equal(-,_,fixnum): equalregfix
equal(-,_,flonum): equalregflo
equal(-,_,string): equalregstr
equal(-,_,special): equalregspec
equal(-,fixnum,_): equalfixreg
equal(-,fixnum,flonum): equalfixflo
equal(-,fixnum,string): equalfixstr
equal(-,fixnum,special): equalfixspec
equal(-,flonum,_): equalfloreg
equal(-,flonum,fixnum): equalflofix
equal(-,flonum,string): equalflostr
equal(-,flonum,special): equalflospec
equal(-,string,_): equalstrreg
equal(-,string,fixnum): equalstrfix
equal(-,string,flonum): equalstrflo
equal(-,string,special): equalstrspec
equal(-,special,_): equalspecreg
equal(-,special,fixnum): equalspecfix
equal(-,special,flonum): equalspecflo
equal(-,special,string): equalspecstr
getprop(-,_,fixnum): getpropregfix
getprop(-,_,flonum): getpropregflo
getprop(-,_,string): getpropregstr
getprop(-,_,special): getpropregspec
getprop(-,fixnum,_): getpropfixreg
getprop(-,fixnum,flonum): getpropfixflo
getprop(-,fixnum,string): getpropfixstr
getprop(-,fixnum,special): getpropfixspec
getprop(-,flonum,_): getpropfloreg
getprop(-,flonum,fixnum): getpropflofix
getprop(-,flonum,string): getpropflostr
getprop(-,flonum,special): getpropflospec
getprop(-,string,_): getpropstrreg
getprop(-,string,fixnum): getpropstrfix
getprop(-,string,flonum): getpropstrflo
getprop(-,string,special): getpropstrspec
getprop(-,special,_): getpropspecreg
getprop(-,special,fixnum): getpropspecfix
getprop(-,special,flonum): getpropspecflo
getprop(-,special,string): getpropspecstr
leftshift(-,_,fixnum): leftshiftregfix
leftshift(-,_,flonum): leftshiftregflo
leftshift(-,_,string): leftshiftregstr
leftshift(-,_,special): leftshiftregspec
leftshift(-,fixnum,_): leftshiftfixreg
leftshift(-,fixnum,flonum): leftshiftfixflo
leftshift(-,fixnum,string): leftshiftfixstr
leftshift(-,fixnum,special): leftshiftfixspec
leftshift(-,flonum,_): leftshiftfloreg
leftshift(-,flonum,fixnum): leftshiftflofix
leftshift(-,flonum,string): leftshiftflostr
leftshift(-,flonum,special): leftshiftflospec
leftshift(-,string,_): leftshiftstrreg
leftshift(-,string,fixnum): leftshiftstrfix
leftshift(-,string,flonum): leftshiftstrflo
leftshift(-,string,special): leftshiftstrspec
leftshift(-,special,_): leftshiftspecreg
leftshift(-,special,fixnum): leftshiftspecfix
leftshift(-,special,flonum): leftshiftspecflo
leftshift(-,special,string): leftshiftspecstr
lessthan(-,_,fixnum): lessthanregfix
lessthan(-,_,flonum): lessthanregflo
lessthan(-,_,string): lessthanregstr
lessthan(-,_,special): lessthanregspec
lessthan(-,fixnum,_): lessthanfixreg
lessthan(-,fixnum,flonum): lessthanfixflo
lessthan(-,fixnum,string): lessthanfixstr
lessthan(-,fixnum,special): lessthanfixspec
lessthan(-,flonum,_): lessthanfloreg
lessthan(-,flonum,fixnum): lessthanflofix
lessthan(-,flonum,string): lessthanflostr
lessthan(-,flonum,special): lessthanflospec
lessthan(-,string,_): lessthanstrreg
lessthan(-,string,fixnum): lessthanstrfix
lessthan(-,string,flonum): lessthanstrflo
lessthan(-,string,special): lessthanstrspec
lessthan(-,special,_): lessthanspecreg
lessthan(-,special,fixnum): lessthanspecfix
lessthan(-,special,flonum): lessthanspecflo
lessthan(-,special,string): lessthanspecstr
lessthanequal(-,_,fixnum): lessthanequalregfix
lessthanequal(-,_,flonum): lessthanequalregflo
lessthanequal(-,_,string): lessthanequalregstr
lessthanequal(-,_,special): lessthanequalregspec
lessthanequal(-,fixnum,_): lessthanequalfixreg
lessthanequal(-,fixnum,flonum): lessthanequalfixflo
lessthanequal(-,fixnum,string): lessthanequalfixstr
lessthanequal(-,fixnum,special): lessthanequalfixspec
lessthanequal(-,flonum,_): lessthanequalfloreg
lessthanequal(-,flonum,fixnum): lessthanequalflofix
lessthanequal(-,flonum,string): lessthanequalflostr
lessthanequal(-,flonum,special): lessthanequalflospec
lessthanequal(-,string,_): lessthanequalstrreg
lessthanequal(-,string,fixnum): lessthanequalstrfix
lessthanequal(-,string,flonum): lessthanequalstrflo
lessthanequal(-,string,special): lessthanequalstrspec
lessthanequal(-,special,_): lessthanequalspecreg
lessthanequal(-,special,fixnum): lessthanequalspecfix
lessthanequal(-,special,flonum): lessthanequalspecflo
lessthanequal(-,special,string): lessthanequalspecstr
mod(-,_,fixnum): modregfix
mod(-,_,flonum): modregflo
mod(-,_,string): modregstr
mod(-,_,special): modregspec
mod(-,fixnum,_): modfixreg
mod(-,fixnum,flonum): modfixflo
mod(-,fixnum,string): modfixstr
mod(-,fixnum,special): modfixspec
mod(-,flonum,_): modfloreg
mod(-,flonum,fixnum): modflofix
mod(-,flonum,string): modflostr
mod(-,flonum,special): modflospec
mod(-,string,_): modstrreg
mod(-,string,fixnum): modstrfix
mod(-,string,flonum): modstrflo
mod(-,string,special): modstrspec
mod(-,special,_): modspecreg
mod(-,special,fixnum): modspecfix
mod(-,special,flonum): modspecflo
mod(-,special,string): modspecstr
mul(-,_,fixnum): mulregfix
mul(-,_,flonum): mulregflo
mul(-,_,string): mulregstr
mul(-,_,special): mulregspec
mul(-,fixnum,_): mulfixreg
mul(-,fixnum,flonum): mulfixflo
mul(-,fixnum,string): mulfixstr
mul(-,fixnum,special): mulfixspec
mul(-,flonum,_): mulfloreg
mul(-,flonum,fixnum): mulflofix
mul(-,flonum,string): mulflostr
mul(-,flonum,special): mulflospec
mul(-,string,_): mulstrreg
mul(-,string,fixnum): mulstrfix
mul(-,string,flonum): mulstrflo
mul(-,string,special): mulstrspec
mul(-,special,_): mulspecreg
mul(-,special,fixnum): mulspecfix
mul(-,special,flonum): mulspecflo
mul(-,special,string): mulspecstr
rightshift(-,_,fixnum): rightshiftregfix
rightshift(-,_,flonum): rightshiftregflo
rightshift(-,_,string): rightshiftregstr
rightshift(-,_,special): rightshiftregspec
rightshift(-,fixnum,_): rightshiftfixreg
rightshift(-,fixnum,flonum): rightshiftfixflo
rightshift(-,fixnum,string): rightshiftfixstr
rightshift(-,fixnum,special): rightshiftfixspec
rightshift(-,flonum,_): rightshiftfloreg
rightshift(-,flonum,fixnum): rightshiftflofix
rightshift(-,flonum,string): rightshiftflostr
rightshift(-,flonum,special): rightshiftflospec
rightshift(-,string,_): rightshiftstrreg
rightshift(-,string,fixnum): rightshiftstrfix
rightshift(-,string,flonum): rightshiftstrflo
rightshift(-,string,special): rightshiftstrspec
rightshift(-,special,_): rightshiftspecreg
rightshift(-,special,fixnum): rightshiftspecfix
rightshift(-,special,flonum): rightshiftspecflo
rightshift(-,special,string): rightshiftspecstr
sub(-,_,fixnum): subregfix
sub(-,_,flonum): subregflo
sub(-,_,string): subregstr
sub(-,_,special): subregspec
sub(-,fixnum,_): subfixreg
sub(-,fixnum,flonum): subfixflo
sub(-,fixnum,string): subfixstr
sub(-,fixnum,special): subfixspec
sub(-,flonum,_): subfloreg
sub(-,flonum,fixnum): subflofix
sub(-,flonum,string): subflostr
sub(-,flonum,special): subflospec
sub(-,string,_): substrreg
sub(-,string,fixnum): substrfix
sub(-,string,flonum): substrflo
sub(-,string,special): substrspec
sub(-,special,_): subspecreg
sub(-,special,fixnum): subspecfix
sub(-,special,flonum): subspecflo
sub(-,special,string): subspecstr
unsignedrightshift(-,_,fixnum): unsignedrightshiftregfix
unsignedrightshift(-,_,flonum): unsignedrightshiftregflo
unsignedrightshift(-,_,string): unsignedrightshiftregstr
unsignedrightshift(-,_,special): unsignedrightshiftregspec
unsignedrightshift(-,fixnum,_): unsignedrightshiftfixreg
unsignedrightshift(-,fixnum,flonum): unsignedrightshiftfixflo
unsignedrightshift(-,fixnum,string): unsignedrightshiftfixstr
unsignedrightshift(-,fixnum,special): unsignedrightshiftfixspec
unsignedrightshift(-,flonum,_): unsignedrightshiftfloreg
unsignedrightshift(-,flonum,fixnum): unsignedrightshiftflofix
unsignedrightshift(-,flonum,string): unsignedrightshiftflostr
unsignedrightshift(-,flonum,special): unsignedrightshiftflospec
unsignedrightshift(-,string,_): unsignedrightshiftstrreg
unsignedrightshift(-,string,fixnum): unsignedrightshiftstrfix
unsignedrightshift(-,string,flonum): unsignedrightshiftstrflo
unsignedrightshift(-,string,special): unsignedrightshiftstrspec
unsignedrightshift(-,special,_): unsignedrightshiftspecreg
unsignedrightshift(-,special,fixnum): unsignedrightshiftspecfix
unsignedrightshift(-,special,flonum): unsignedrightshiftspecflo
unsignedrightshift(-,special,string): unsignedrightshiftspecstr
setprop(_,_,fixnum): setpropregregfix
setprop(_,_,flonum): setpropregregflo
setprop(_,_,string): setpropregregstr
setprop(_,_,special): setpropregregspec
setprop(_,fixnum,_): setpropregfixreg
setprop(_,fixnum,fixnum): setpropregfixfix
setprop(_,fixnum,flonum): setpropregfixflo
setprop(_,fixnum,string): setpropregfixstr
setprop(_,fixnum,special): setpropregfixspec
setprop(_,flonum,_): setpropregfloreg
setprop(_,flonum,fixnum): setpropregflofix
setprop(_,flonum,flonum): setpropregfloflo
setprop(_,flonum,string): setpropregflostr
setprop(_,flonum,special): setpropregflospec
setprop(_,string,_): setpropregstrreg
setprop(_,string,fixnum): setpropregstrfix
setprop(_,string,flonum): setpropregstrflo
setprop(_,string,string): setpropregstrstr
setprop(_,string,special): setpropregstrspec
setprop(_,special,_): setpropregspecreg
setprop(_,special,fixnum): setpropregspecfix
setprop(_,special,flonum): setpropregspecflo
setprop(_,special,string): setpropregspecstr
setprop(_,special,special): setpropregspecspec
setprop(fixnum,_,_): setpropfixregreg
setprop(fixnum,_,fixnum): setpropfixregfix
setprop(fixnum,_,flonum): setpropfixregflo
setprop(fixnum,_,string): setpropfixregstr
setprop(fixnum,_,special): setpropfixregspec
setprop(fixnum,fixnum,_): setpropfixfixreg
setprop(fixnum,fixnum,fixnum): setpropfixfixfix
setprop(fixnum,fixnum,flonum): setpropfixfixflo
setprop(fixnum,fixnum,string): setpropfixfixstr
setprop(fixnum,fixnum,special): setpropfixfixspec
setprop(fixnum,flonum,_): setpropfixfloreg
setprop(fixnum,flonum,fixnum): setpropfixflofix
setprop(fixnum,flonum,flonum): setpropfixfloflo
setprop(fixnum,flonum,string): setpropfixflostr
setprop(fixnum,flonum,special): setpropfixflospec
setprop(fixnum,string,_): setpropfixstrreg
setprop(fixnum,string,fixnum): setpropfixstrfix
setprop(fixnum,string,flonum): setpropfixstrflo
setprop(fixnum,string,string): setpropfixstrstr
setprop(fixnum,string,special): setpropfixstrspec
setprop(fixnum,special,_): setpropfixspecreg
setprop(fixnum,special,fixnum): setpropfixspecfix
setprop(fixnum,special,flonum): setpropfixspecflo
setprop(fixnum,special,string): setpropfixspecstr
setprop(fixnum,special,special): setpropfixspecspec
setprop(flonum,_,_): setpropfloregreg
setprop(flonum,_,fixnum): setpropfloregfix
setprop(flonum,_,flonum): setpropfloregflo
setprop(flonum,_,string): setpropfloregstr
setprop(flonum,_,special): setpropfloregspec
setprop(flonum,fixnum,_): setpropflofixreg
setprop(flonum,fixnum,fixnum): setpropflofixfix
setprop(flonum,fixnum,flonum): setpropflofixflo
setprop(flonum,fixnum,string): setpropflofixstr
setprop(flonum,fixnum,special): setpropflofixspec
setprop(flonum,flonum,_): setpropflofloreg
setprop(flonum,flonum,fixnum): setpropfloflofix
setprop(flonum,flonum,flonum): setpropflofloflo
setprop(flonum,flonum,string): setpropfloflostr
setprop(flonum,flonum,special): setpropfloflospec
setprop(flonum,string,_): setpropflostrreg
setprop(flonum,string,fixnum): setpropflostrfix
setprop(flonum,string,flonum): setpropflostrflo
setprop(flonum,string,string): setpropflostrstr
setprop(flonum,string,special): setpropflostrspec
setprop(flonum,special,_): setpropflospecreg
setprop(flonum,special,fixnum): setpropflospecfix
setprop(flonum,special,flonum): setpropflospecflo
setprop(flonum,special,string): setpropflospecstr
setprop(flonum,special,special): setpropflospecspec
setprop(string,_,_): setpropstrregreg
setprop(string,_,fixnum): setpropstrregfix
setprop(string,_,flonum): setpropstrregflo
setprop(string,_,string): setpropstrregstr
setprop(string,_,special): setpropstrregspec
setprop(string,fixnum,_): setpropstrfixreg
setprop(string,fixnum,fixnum): setpropstrfixfix
setprop(string,fixnum,flonum): setpropstrfixflo
setprop(string,fixnum,string): setpropstrfixstr
setprop(string,fixnum,special): setpropstrfixspec
setprop(string,flonum,_): setpropstrfloreg
setprop(string,flonum,fixnum): setpropstrflofix
setprop(string,flonum,flonum): setpropstrfloflo
setprop(string,flonum,string): setpropstrflostr
setprop(string,flonum,special): setpropstrflospec
setprop(string,string,_): setpropstrstrreg
setprop(string,string,fixnum): setpropstrstrfix
setprop(string,string,flonum): setpropstrstrflo
setprop(string,string,string): setpropstrstrstr
setprop(string,string,special): setpropstrstrspec
setprop(string,special,_): setpropstrspecreg
setprop(string,special,fixnum): setpropstrspecfix
setprop(string,special,flonum): setpropstrspecflo
setprop(string,special,string): setpropstrspecstr
setprop(string,special,special): setpropstrspecspec
setprop(special,_,_): setpropspecregreg
setprop(special,_,fixnum): setpropspecregfix
setprop(special,_,flonum): setpropspecregflo
setprop(special,_,string): setpropspecregstr
setprop(special,_,special): setpropspecregspec
setprop(special,fixnum,_): setpropspecfixreg
setprop(special,fixnum,fixnum): setpropspecfixfix
setprop(special,fixnum,flonum): setpropspecfixflo
setprop(special,fixnum,string): setpropspecfixstr
setprop(special,fixnum,special): setpropspecfixspec
setprop(special,flonum,_): setpropspecfloreg
setprop(special,flonum,fixnum): setpropspecflofix
setprop(special,flonum,flonum): setpropspecfloflo
setprop(special,flonum,string): setpropspecflostr
setprop(special,flonum,special): setpropspecflospec
setprop(special,string,_): setpropspecstrreg
setprop(special,string,fixnum): setpropspecstrfix
setprop(special,string,flonum): setpropspecstrflo
setprop(special,string,string): setpropspecstrstr
setprop(special,string,special): setpropspecstrspec
setprop(special,special,_): setpropspecspecreg
setprop(special,special,fixnum): setpropspecspecfix
setprop(special,special,flonum): setpropspecspecflo
setprop(special,special,string): setpropspecspecstr
setprop(special,special,special): setpropspecspecspec