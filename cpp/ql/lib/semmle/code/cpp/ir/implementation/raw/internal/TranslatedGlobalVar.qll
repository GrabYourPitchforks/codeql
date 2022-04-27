import semmle.code.cpp.ir.implementation.raw.internal.TranslatedElement
private import cpp
private import semmle.code.cpp.ir.implementation.IRType
private import semmle.code.cpp.ir.implementation.Opcode
private import semmle.code.cpp.ir.implementation.internal.OperandTag
private import semmle.code.cpp.ir.internal.CppType
private import TranslatedInitialization
private import InstructionTag

class TranslatedGlobalOrNamespaceVarInit extends TranslatedRootElement,
  TTranslatedGlobalOrNamespaceVarInit, InitializationContext {
  GlobalOrNamespaceVariable var;

  TranslatedGlobalOrNamespaceVarInit() { this = TTranslatedGlobalOrNamespaceVarInit(var) }

  override string toString() { result = var.toString() }

  final override GlobalOrNamespaceVariable getAst() { result = var }

  final override Declaration getFunction() { result = var }

  final Location getLocation() { result = var.getLocation() }

  override Instruction getFirstInstruction() { result = this.getInstruction(EnterFunctionTag()) }

  override TranslatedElement getChild(int n) {
    n = 1 and
    result = getTranslatedInitialization(var.getInitializer().getExpr().getFullyConverted())
  }

  override predicate hasInstruction(Opcode op, InstructionTag tag, CppType type) {
    op instanceof Opcode::EnterFunction and
    tag = EnterFunctionTag() and
    type = getVoidType()
    or
    op instanceof Opcode::AliasedDefinition and
    tag = AliasedDefinitionTag() and
    type = getUnknownType()
    or
    op instanceof Opcode::VariableAddress and
    tag = InitializerVariableAddressTag() and
    type = getTypeForGLValue(var.getType())
    or
    op instanceof Opcode::ReturnVoid and
    tag = ReturnTag() and
    type = getVoidType()
    or
    op instanceof Opcode::AliasedUse and
    tag = AliasedUseTag() and
    type = getVoidType()
    or
    op instanceof Opcode::ExitFunction and
    tag = ExitFunctionTag() and
    type = getVoidType()
  }

  override Instruction getInstructionSuccessor(InstructionTag tag, EdgeKind kind) {
    kind instanceof GotoEdge and
    (
      tag = EnterFunctionTag() and
      result = getInstruction(AliasedDefinitionTag())
      or
      tag = AliasedDefinitionTag() and
      result = getInstruction(InitializerVariableAddressTag())
      or
      tag = InitializerVariableAddressTag() and
      result = getChild(1).getFirstInstruction()
      or
      tag = ReturnTag() and
      result = getInstruction(AliasedUseTag())
      or
      tag = AliasedUseTag() and
      result = getInstruction(ExitFunctionTag())
    )
  }

  override Instruction getChildSuccessor(TranslatedElement child) {
    child = getChild(1) and
    result = getInstruction(ReturnTag())
  }

  final override CppType getInstructionMemoryOperandType(
    InstructionTag tag, TypedOperandTag operandTag
  ) {
    tag = AliasedUseTag() and
    operandTag instanceof SideEffectOperandTag and
    result = getUnknownType()
  }

  override IRUserVariable getInstructionVariable(InstructionTag tag) {
    tag = InitializerVariableAddressTag() and
    result.getVariable() = var
  }

  override Instruction getTargetAddress() {
    result = getInstruction(InitializerVariableAddressTag())
  }

  override Type getTargetType() { result = var.getUnspecifiedType() }
}

TranslatedGlobalOrNamespaceVarInit getTranslatedVarInit(GlobalOrNamespaceVariable var) {
  result.getAst() = var
}