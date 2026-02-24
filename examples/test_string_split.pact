fn main() {
    // Basic split
    let parts = "a,b,c".split(",")
    io.println("split count: {parts.len()}")
    io.println("split 0: {parts.get(0)}")
    io.println("split 1: {parts.get(1)}")
    io.println("split 2: {parts.get(2)}")

    // Split with space
    let words = "hello world foo".split(" ")
    io.println("words count: {words.len()}")
    io.println("word 0: {words.get(0)}")
    io.println("word 2: {words.get(2)}")

    // No match — entire string as one element
    let no_match = "abc".split("x")
    io.println("no match count: {no_match.len()}")
    io.println("no match 0: {no_match.get(0)}")

    // Empty segments
    let empties = "a,,b".split(",")
    io.println("empties count: {empties.len()}")
    io.println("empties 1: {empties.get(1)}")

    // Join with comma
    let joined = parts.join(",")
    io.println("joined: {joined}")

    // Join with space
    let spaced = words.join(" ")
    io.println("spaced: {spaced}")

    // Join with empty delimiter
    let dense = parts.join("")
    io.println("dense: {dense}")

    // Empty list join
    let empty_list: List[Str] = []
    let empty_joined = empty_list.join(",")
    io.println("empty join: '{empty_joined}'")

    // Round-trip
    let csv = "x,y,z"
    let rt = csv.split(",").join(",")
    io.println("round-trip: {rt}")
}
