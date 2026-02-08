import builtins

class PactSome:
    def __init__(self, value):
        self.value = value

    def unwrap(self):
        return self.value

    def is_some(self):
        return True

    def is_none(self):
        return False

    def parse_int(self):
        if hasattr(self.value, 'parse_int'):
            return self.value.parse_int()
        try:
            return PactSome(int(self.value))
        except (ValueError, TypeError):
            return NONE

    def map(self, fn):
        return PactSome(fn(self.value))

    def __eq__(self, other):
        return isinstance(other, PactSome) and self.value == other.value

    def __str__(self):
        return str(self.value)

    def __repr__(self):
        return f"Some({self.value!r})"


class _PactNone:
    def unwrap(self):
        raise RuntimeError("called unwrap on None")

    def is_some(self):
        return False

    def is_none(self):
        return True

    def parse_int(self):
        return NONE

    def as_float(self):
        return NONE

    def as_str(self):
        return NONE

    def map(self, fn):
        return NONE

    def __str__(self):
        return "None"


NONE = _PactNone()


class PactList:
    def __init__(self, items):
        self._items = list(items)

    def get(self, index):
        if 0 <= index < len(self._items):
            return PactSome(self._items[index])
        return NONE

    def len(self):
        return len(self._items)

    def append(self, item):
        return PactList(self._items + [item])

    def set(self, index, value):
        new_items = list(self._items)
        new_items[index] = value
        return PactList(new_items)

    def map(self, fn):
        return PactList([fn(item) for item in self._items])

    def join(self, sep):
        return sep.join(str(item) for item in self._items)

    def find(self, fn):
        for item in self._items:
            if fn(item):
                return PactSome(item)
        return NONE

    def filter(self, fn):
        return PactList([item for item in self._items if fn(item)])

    def fold(self, init, fn):
        acc = init
        for item in self._items:
            acc = fn(acc, item)
        return acc

    def collect(self):
        return PactList(list(self._items))

    def enumerate(self):
        return PactList([tuple((i, item)) for i, item in builtins.enumerate(self._items)])

    def chain(self, other):
        if isinstance(other, PactList):
            return PactList(self._items + other._items)
        return PactList(self._items + list(other))

    def zip(self, other):
        other_items = other._items if isinstance(other, PactList) else list(other)
        return PactList([tuple((a, b)) for a, b in builtins.zip(self._items, other_items)])

    def flat_map(self, fn):
        result = []
        for item in self._items:
            mapped = fn(item)
            if isinstance(mapped, PactList):
                result.extend(mapped._items)
            else:
                result.extend(mapped)
        return PactList(result)

    def count(self):
        return len(self._items)

    def any(self, fn):
        return builtins.any(fn(item) for item in self._items)

    def all(self, fn):
        return builtins.all(fn(item) for item in self._items)

    def for_each(self, fn):
        for item in self._items:
            fn(item)

    def filter_map(self, fn):
        result = []
        for item in self._items:
            val = fn(item)
            if isinstance(val, PactSome):
                result.append(val.value)
            elif not isinstance(val, _PactNone):
                if val is not None:
                    result.append(val)
        return PactList(result)

    def into_iter(self):
        return self

    def next(self):
        if not hasattr(self, '_iter_index'):
            self._iter_index = 0
        if self._iter_index >= len(self._items):
            return NONE
        val = self._items[self._iter_index]
        self._iter_index += 1
        return PactSome(val)

    def sort_by(self, fn):
        return PactList(sorted(self._items, key=fn))

    def push(self, item):
        return PactList(self._items + [item])

    def __iter__(self):
        return iter(self._items)

    def __eq__(self, other):
        return isinstance(other, PactList) and self._items == other._items

    def __repr__(self):
        return f"[{', '.join(repr(i) for i in self._items)}]"


class PactOk:
    def __init__(self, value):
        self.value = value

    def unwrap(self):
        return self.value

    def is_ok(self):
        return True

    def is_err(self):
        return False

    def unwrap_err(self):
        raise RuntimeError(f"called unwrap_err on Ok: {self.value}")

    def map_err(self, fn):
        return self

    def __eq__(self, other):
        return isinstance(other, PactOk) and self.value == other.value

    def __repr__(self):
        return f"Ok({self.value!r})"

    def __str__(self):
        return f"Ok({self.value})"


class PactErr:
    def __init__(self, value):
        self.value = value

    def unwrap(self):
        raise RuntimeError(f"called unwrap on Err: {self.value}")

    def is_ok(self):
        return False

    def is_err(self):
        return True

    def unwrap_err(self):
        return self.value

    def map_err(self, fn):
        return PactErr(fn(self.value))

    def __eq__(self, other):
        return isinstance(other, PactErr) and self.value == other.value

    def __repr__(self):
        return f"Err({self.value!r})"

    def __str__(self):
        return f"Err({self.value})"


class PactEnumVariant:
    def __init__(self, type_name, variant_name, fields):
        self.type_name = type_name
        self.variant_name = variant_name
        self.fields = fields

    def __eq__(self, other):
        return (
            isinstance(other, PactEnumVariant)
            and self.type_name == other.type_name
            and self.variant_name == other.variant_name
            and self.fields == other.fields
        )

    def __repr__(self):
        if self.fields:
            args = ", ".join(repr(f) for f in self.fields)
            return f"{self.type_name}.{self.variant_name}({args})"
        return f"{self.type_name}.{self.variant_name}"

    def __str__(self):
        return self.__repr__()


class PactEnumType:
    def __init__(self, name, variant_defs):
        self.name = name
        self.variant_defs = variant_defs

    def construct(self, variant_name, args):
        return PactEnumVariant(self.name, variant_name, list(args))


class PactStruct:
    def __init__(self, type_name, fields):
        self._type_name = type_name
        self._fields = dict(fields)

    def __getattr__(self, name):
        if name.startswith("_"):
            raise AttributeError(name)
        if name in self._fields:
            return self._fields[name]
        if self._type_name == "_Anon":
            return NONE
        raise AttributeError(f"{self._type_name} has no field '{name}'")

    def __eq__(self, other):
        return (
            isinstance(other, PactStruct)
            and self._type_name == other._type_name
            and self._fields == other._fields
        )

    def __repr__(self):
        fields = ", ".join(f"{k}: {v!r}" for k, v in self._fields.items())
        return f"{self._type_name} {{ {fields} }}"

    def __str__(self):
        return self.__repr__()


class IOHandle:
    def println(self, value):
        print(value)

    def log(self, value):
        print(f"[LOG] {value}")


class FSHandle:
    def write(self, path, content):
        print(content)


class DBHandle:
    def query_one(self, query):
        return NONE

    def execute(self, query):
        pass


class PactMap:
    def __init__(self, entries=None):
        self._data = dict(entries or [])

    @staticmethod
    def new():
        return PactMap()

    @staticmethod
    def of(pairs_list):
        entries = []
        for pair in pairs_list:
            if isinstance(pair, tuple) and len(pair) == 2:
                entries.append(pair)
        return PactMap(entries)

    @staticmethod
    def from_list(pairs_list):
        return PactMap.of(pairs_list)

    def get(self, key):
        if key in self._data:
            return PactSome(self._data[key])
        return NONE

    def insert(self, key, value):
        new_data = dict(self._data)
        new_data[key] = value
        return PactMap(list(new_data.items()))

    def contains_key(self, key):
        return key in self._data

    def keys(self):
        return PactList(list(self._data.keys()))

    def values(self):
        return PactList(list(self._data.values()))

    def len(self):
        return len(self._data)

    def into_iter(self):
        return PactList([tuple((k, v)) for k, v in self._data.items()])

    def __iter__(self):
        return iter(tuple((k, v)) for k, v in self._data.items())

    def __repr__(self):
        return f"Map({self._data!r})"


class PactResponse:
    def __init__(self, status, body_text):
        self._status = status
        self._body = body_text

    @staticmethod
    def new(status, body_text):
        return PactResponse(status, body_text)

    def body(self):
        return self._body

    def status(self):
        return self._status


class JSONHandle:
    def parse(self, text):
        import json
        try:
            data = json.loads(text)
            return PactJSONValue(data)
        except Exception:
            return NONE


class PactJSONValue:
    def __init__(self, data):
        self._data = data

    def get(self, key):
        if isinstance(self._data, dict) and key in self._data:
            return PactSome(PactJSONValue(self._data[key]))
        return NONE

    def as_float(self):
        if isinstance(self._data, (int, float)):
            return float(self._data)
        return NONE

    def as_str(self):
        if isinstance(self._data, str):
            return self._data
        return NONE

    def __repr__(self):
        return f"JSONValue({self._data!r})"


class PactString:
    """Wraps a str to give it Pact methods."""
    def __init__(self, value):
        self._value = value

    def parse_int(self):
        try:
            return PactSome(int(self._value))
        except (ValueError, TypeError):
            return NONE

    def len(self):
        return len(self._value)

    def is_some(self):
        return True

    def is_none(self):
        return False

    def __str__(self):
        return self._value

    def __repr__(self):
        return repr(self._value)

    def __eq__(self, other):
        if isinstance(other, str):
            return self._value == other
        if isinstance(other, PactString):
            return self._value == other._value
        return False

    def __hash__(self):
        return hash(self._value)

    def __add__(self, other):
        return PactString(self._value + str(other))

    def split(self, sep):
        return PactList(self._value.split(sep))

    def contains(self, sub):
        return sub in self._value

    def starts_with(self, prefix):
        return self._value.startswith(prefix)

    def ends_with(self, suffix):
        return self._value.endswith(suffix)

    def trim(self):
        return self._value.strip()

    def to_uppercase(self):
        return self._value.upper()

    def to_lowercase(self):
        return self._value.lower()

    def replace(self, old, new):
        return self._value.replace(old, new)

    def chars(self):
        return PactList(list(self._value))


class PactRequest:
    def __init__(self, params=None, body_data=None):
        self._params = params or {}
        self._body_data = body_data

    def param(self, name):
        val = self._params.get(name, "")
        return PactString(val)

    def body(self):
        if self._body_data:
            return self._body_data
        return NONE


class PactResponseBuilder:
    def __init__(self, status=200, body=None):
        self._status = status
        self._body = body

    @staticmethod
    def json(data):
        return PactResponseBuilder(200, data)

    @staticmethod
    def bad_request(msg):
        return PactResponseBuilder(400, msg)

    @staticmethod
    def not_found(msg):
        return PactResponseBuilder(404, msg)

    @staticmethod
    def internal_error(msg):
        return PactResponseBuilder(500, msg)

    def with_status(self, status):
        return PactResponseBuilder(status, self._body)

    def __repr__(self):
        return f"Response({self._status}, {self._body!r})"


class ServerHandle:
    def __init__(self, host, port):
        self._host = host
        self._port = port

    def route(self, method, path, handler):
        pass

    def serve(self):
        pass


class NetHandle:
    def get(self, url):
        return PactOk(PactResponse(200, '{"temp_c": 0.0, "summary": "stub"}'))

    def listen(self, host, port):
        if isinstance(host, _PactNone):
            host = "0.0.0.0"
        return ServerHandle(str(host), port)


class EnvHandle:
    def __init__(self, argv):
        self._argv = argv

    def args(self):
        return PactList(self._argv)

    def var(self, name):
        import os
        val = os.environ.get(name)
        if val is not None:
            return PactSome(PactString(val))
        return NONE
