import dataclasses


@dataclasses.dataclass
class IntLit:
    value: int


@dataclasses.dataclass
class Ident:
    name: str


@dataclasses.dataclass
class InterpString:
    parts: list  # list[str | Expr]


@dataclasses.dataclass
class Call:
    func: object  # Expr
    args: list


@dataclasses.dataclass
class MethodCall:
    obj: object  # Expr
    method: str
    args: list


@dataclasses.dataclass
class BinOp:
    op: str
    left: object  # Expr
    right: object  # Expr


@dataclasses.dataclass
class LetBinding:
    name: str
    value: object  # Expr
    is_mut: bool = False
    pattern: object = None  # optional destructuring pattern (e.g. tuple)
    type_ann: object = None  # optional TypeAnnotation


@dataclasses.dataclass
class ExprStmt:
    expr: object  # Expr


@dataclasses.dataclass
class Param:
    name: str
    type_name: str | None = None
    default: object = None


@dataclasses.dataclass
class Block:
    stmts: list


@dataclasses.dataclass
class FnDef:
    name: str
    params: list[Param]
    body: Block
    return_type: object = None  # TypeAnnotation
    effects: list = dataclasses.field(default_factory=list)
    is_pub: bool = False
    annotations: list = dataclasses.field(default_factory=list)


@dataclasses.dataclass
class TupleLit:
    elements: list


@dataclasses.dataclass
class RangeLit:
    start: object  # Expr
    end: object  # Expr
    inclusive: bool = False


@dataclasses.dataclass
class IntPattern:
    value: int


@dataclasses.dataclass
class WildcardPattern:
    pass


@dataclasses.dataclass
class IdentPattern:
    name: str


@dataclasses.dataclass
class TuplePattern:
    elements: list


@dataclasses.dataclass
class MatchArm:
    pattern: object
    body: object  # Expr
    guard: object = None


@dataclasses.dataclass
class MatchExpr:
    scrutinee: object  # Expr
    arms: list[MatchArm]


@dataclasses.dataclass
class ForIn:
    var_name: str
    iterable: object  # Expr
    body: Block
    pattern: object = None


@dataclasses.dataclass
class FloatLit:
    value: float


@dataclasses.dataclass
class BoolLit:
    value: bool


@dataclasses.dataclass
class ListLit:
    elements: list


@dataclasses.dataclass
class StructLit:
    type_name: str
    fields: list  # list[StructLitField]


@dataclasses.dataclass
class StructLitField:
    name: str
    value: object  # Expr


@dataclasses.dataclass
class FieldAccess:
    obj: object  # Expr
    field: str


@dataclasses.dataclass
class IndexExpr:
    obj: object  # Expr
    index: object  # Expr


@dataclasses.dataclass
class UnaryOp:
    op: str
    operand: object  # Expr


@dataclasses.dataclass
class Assignment:
    target: object  # Expr (Ident or FieldAccess)
    value: object  # Expr


@dataclasses.dataclass
class CompoundAssignment:
    op: str  # "+", "-", "*", "/"
    target: object  # Expr (Ident or FieldAccess)
    value: object  # Expr


@dataclasses.dataclass
class IfExpr:
    condition: object  # Expr
    then_body: Block
    else_body: Block | None = None


@dataclasses.dataclass
class ReturnExpr:
    value: object | None = None  # Expr


@dataclasses.dataclass
class Closure:
    params: list[Param]
    body: Block


@dataclasses.dataclass
class WhileLoop:
    condition: object  # Expr
    body: Block


@dataclasses.dataclass
class LoopExpr:
    body: Block


@dataclasses.dataclass
class BreakStmt:
    pass


@dataclasses.dataclass
class ContinueStmt:
    pass


@dataclasses.dataclass
class WithBlock:
    handlers: list  # list[Expr]
    body: Block
    as_binding: str | None = None


@dataclasses.dataclass
class HandlerExpr:
    effect: str
    methods: list[FnDef]


# --- Type System Nodes ---

@dataclasses.dataclass
class TypeAnnotation:
    name: str
    params: list  # list[TypeAnnotation] for generics
    optional: bool = False


@dataclasses.dataclass
class TypeField:
    name: str
    type_ann: TypeAnnotation
    default: object = None


@dataclasses.dataclass
class TypeVariant:
    name: str
    fields: list[TypeField]  # empty for unit variants


@dataclasses.dataclass
class TypeDef:
    name: str
    type_params: list[str]
    fields: list[TypeField]  # product type fields
    variants: list[TypeVariant]  # sum type variants
    annotations: list  # list[Annotation]


@dataclasses.dataclass
class TraitDef:
    name: str
    type_params: list[str]
    super_traits: list[str]
    methods: list[FnDef]


@dataclasses.dataclass
class ImplBlock:
    trait_name: str
    type_name: str
    type_params: list[str]
    methods: list[FnDef]


@dataclasses.dataclass
class TestBlock:
    name: str
    body: Block


@dataclasses.dataclass
class Annotation:
    name: str
    args: list  # list[Expr]


# --- Patterns ---

@dataclasses.dataclass
class StringPattern:
    value: str


@dataclasses.dataclass
class OrPattern:
    alternatives: list


@dataclasses.dataclass
class RangePattern:
    start: object
    end: object
    inclusive: bool


@dataclasses.dataclass
class StructPatternField:
    name: str
    pattern: object = None

@dataclasses.dataclass
class StructPattern:
    type_name: str
    fields: list
    rest: bool = False


@dataclasses.dataclass
class EnumPattern:
    variant: str
    fields: list[str]


@dataclasses.dataclass
class AsPattern:
    name: str
    inner: object


@dataclasses.dataclass
class ModBlock:
    name: str
    body: object  # Program


@dataclasses.dataclass
class ImportStmt:
    path: str
    names: list[str]


# --- Top-level ---

@dataclasses.dataclass
class Program:
    functions: list[FnDef]
    types: list[TypeDef] = dataclasses.field(default_factory=list)
    traits: list[TraitDef] = dataclasses.field(default_factory=list)
    impls: list[ImplBlock] = dataclasses.field(default_factory=list)
    tests: list[TestBlock] = dataclasses.field(default_factory=list)
    annotations: list = dataclasses.field(default_factory=list)  # module-level
    imports: list[ImportStmt] = dataclasses.field(default_factory=list)
    modules: list[ModBlock] = dataclasses.field(default_factory=list)
    top_lets: list[LetBinding] = dataclasses.field(default_factory=list)
