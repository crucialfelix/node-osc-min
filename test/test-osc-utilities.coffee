#
# This file was used for TDD and as such probably has limited utility as
# actual unit tests.
#

osc = require "osc-utilities"
assert = require "assert"

# Basic string tests.

testString = (str, expected_len) ->
    str : str
    len : expected_len
    
testData = [
    testString("abc", 4)
    testString("abcd", 8)
    testString("abcde", 8)
    testString("abcdef", 8)
    testString("abcdefg", 8)
]

testStringLength = (str, expected_len) ->
    oscstr = osc.toOscString(str)
    assert.strictEqual(oscstr.length, expected_len)

exports["basic strings length"] = ->
    for data in testData
        testStringLength data.str, data.len
    

testStringRoundTrip = (str, strict) ->
    oscstr = osc.toOscString(str)
    str2 = osc.splitOscString(oscstr, strict)?.string
    assert.strictEqual(str, str2)
    
exports["basic strings round trip"] = ->
    for data in testData
        testStringRoundTrip data.str
    
    
exports["non strings fail toOscString"] = ->
    assert.throws -> osc.toOscString(7)
    
    
exports["strings with null characters don't fail toOscString by default"] = ->
    assert.notEqual(osc.toOscString("\u0000"), null)
    
    
exports["strings with null characters fail toOscString in strict mode"] = ->
    assert.throws -> osc.toOscString("\u0000", true)
    
    
exports["osc buffers with no null characters fail splitOscString in strict mode"] = ->
    assert.throws -> osc.splitOscString new Buffer("abc"), true
    

exports["osc buffers with non-null characters after a null character fail fromOscString in strict mode"] = ->
    assert.throws -> osc.fromOscString new Buffer("abc\u0000abcd"), true
    

exports["basic strings pass fromOscString in strict mode"] = ->
    for data in testData
        testStringRoundTrip data.str, true
    

exports["osc buffers with non-four length fail in strict mode"] = ->
    assert.throws -> osc.fromOscString new Buffer("abcd\u0000\u0000"), true
    
exports["splitOscString throws when passed a non-buffer"] = ->
    assert.throws -> osc.splitOscString "test"

exports["splitOscString of an osc-string matches the string"] = ->
    split = osc.splitOscString osc.toOscString "testing it"
    assert.strictEqual(split?.string, "testing it")
    assert.strictEqual(split?.rest?.length, 0)
    

exports["splitOscString works with an over-allocated buffer"] = ->
    buffer = osc.toOscString "testing it"
    overallocated = new Buffer(16)
    buffer.copy(overallocated)
    split = osc.splitOscString overallocated
    assert.strictEqual(split?.string, "testing it")
    assert.strictEqual(split?.rest?.length, 4)
    
    
exports["splitOscString works with just a string by default"] = ->
    split = osc.splitOscString (new Buffer "testing it")
    assert.strictEqual(split?.string, "testing it")
    assert.strictEqual(split?.rest?.length, 0)
    
    
exports["splitOscString strict fails for just a string"] = ->
    assert.throws -> osc.splitOscString (new Buffer "testing it"), true
    

exports["splitOscString strict fails for string with not enough padding"] = ->
    assert.throws -> osc.splitOscString (new Buffer "testing \u0000\u0000"), true
    

exports["splitOscString strict succeeds for strings with valid padding"] = ->
    split = osc.splitOscString (new Buffer "testing it\u0000\u0000aaaa"), true
    assert.strictEqual(split?.string, "testing it")
    assert.strictEqual(split?.rest?.length, 4)
    

exports["splitOscString strict fails for string with invalid padding"] = ->
    assert.throws -> osc.splitOscString (new Buffer "testing it\u0000aaaaa"), true

exports["concatenateBuffers throws when passed a single buffer"] = ->
    assert.throws -> osc.concatenateBuffers new Buffer "test"

exports["concatenateBuffers throws when passed an array of non-buffers"] = ->
    assert.throws -> osc.concatenateBuffers ["bleh"]

exports["toIntegerBuffer throws when passed a non-number"] = ->
    assert.throws -> osc.toIntegerBuffer "abcdefg"

exports["splitInteger fails when sent a buffer that's too small"] = ->
    assert.throws -> osc.splitInteger new Buffer 3, "Int32"
    
exports["splitOscArgument fails when given a bogus type"] = ->
    assert.throws -> osc.splitOscArgument new Buffer 8, "bogus"

exports["fromOscMessage with no type string works"] = ->
    translate = osc.fromOscMessage osc.toOscString "/stuff"
    assert.strictEqual translate?.address, "/stuff"
    assert.deepEqual translate?.arguments, []
    
exports["fromOscMessage with type string and no arguments works"] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString ","
    oscmessage = new Buffer(oscaddr.length + osctype.length)
    oscaddr.copy oscmessage
    osctype.copy oscmessage, oscaddr.length
    translate = osc.fromOscMessage oscmessage
    assert.strictEqual translate?.address, "/stuff"
    assert.deepEqual translate?.arguments, []
    
    
exports["fromOscMessage with string argument works"] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString ",s"
    oscarg = osc.toOscString "argu"
    translate = osc.fromOscMessage osc.concatenateBuffers [oscaddr, osctype, oscarg]
    assert.strictEqual translate?.address, "/stuff"
    assert.strictEqual translate?.arguments?[0]?.type, "string"
    assert.strictEqual translate?.arguments?[0]?.value, "argu"
    
    
exports["fromOscMessage with blob argument works"] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString ",b"
    oscarg = osc.concatenateBuffers [(osc.toIntegerBuffer 4), new Buffer "argu"]
    translate = osc.fromOscMessage osc.concatenateBuffers [oscaddr, osctype, oscarg]
    assert.strictEqual translate?.address, "/stuff"
    assert.strictEqual translate?.arguments?[0]?.type, "blob"
    assert.strictEqual (translate?.arguments?[0]?.value?.toString "utf8"), "argu"
    
    
exports["fromOscMessage with integer argument works"] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString ",i"
    oscarg = osc.toIntegerBuffer 888
    translate = osc.fromOscMessage osc.concatenateBuffers [oscaddr, osctype, oscarg]
    assert.strictEqual translate?.address, "/stuff"
    assert.strictEqual translate?.arguments?[0]?.type, "integer"
    assert.strictEqual (translate?.arguments?[0]?.value), 888
    
    
exports["fromOscMessage with multiple arguments works."] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString ",sbi"
    oscargs = [
                (osc.toOscString "argu")
                (osc.concatenateBuffers [(osc.toIntegerBuffer 4), new Buffer "argu"])
                (osc.toIntegerBuffer 888)
    ]

    oscbuffer = osc.concatenateBuffers [oscaddr, osctype, (osc.concatenateBuffers oscargs)]
    translate = osc.fromOscMessage oscbuffer
    assert.strictEqual translate?.address, "/stuff"
    assert.strictEqual translate?.arguments?[0]?.type, "string"
    assert.strictEqual (translate?.arguments?[0]?.value), "argu"

exports["fromOscMessage strict fails if type string has no comma"] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString "fake"
    assert.throws -> 
        osc.fromOscMessage (osc.concatenateBuffers [oscaddr, osctype]), true
        
exports["fromOscMessage non-strict works if type string has no comma"] = ->
    oscaddr = osc.toOscString "/stuff"
    osctype = osc.toOscString "fake"
    message = osc.fromOscMessage (osc.concatenateBuffers [oscaddr, osctype])
    assert.strictEqual message.address, "/stuff"
    assert.strictEqual message.arguments.length, 0

exports["fromOscMessage strict fails if type address doesn't begin with /"] = ->
    oscaddr = osc.toOscString "stuff"
    osctype = osc.toOscString ","
    assert.throws -> 
        osc.fromOscMessage (osc.concatenateBuffers [oscaddr, osctype]), true
    
        
exports["fromOscBundle works with no messages"] = ->
    oscbundle = osc.toOscString "#bundle"
    osctimetag = osc.toIntegerBuffer 0, "UInt64"
    buffer = osc.concatenateBuffers [oscbundle, osctimetag]
    translate = osc.fromOscBundle buffer
    assert.strictEqual translate?.timetag, 0
    assert.deepEqual translate?.elements, []
    
    
exports["fromOscBundle works with single message"] = ->
    oscbundle = osc.toOscString "#bundle"
    osctimetag = osc.toIntegerBuffer 0, "UInt64"
    oscaddr = osc.toOscString "/addr"
    osctype = osc.toOscString ","
    oscmessage = osc.concatenateBuffers [oscaddr, osctype]
    osclen = osc.toIntegerBuffer oscmessage.length
    buffer = osc.concatenateBuffers [oscbundle, osctimetag, osclen, oscmessage]
    translate = osc.fromOscBundle buffer
    assert.strictEqual translate?.timetag, 0
    assert.strictEqual translate?.elements?.length, 1
    assert.strictEqual translate?.elements?[0]?.address, "/addr"
    
    
exports["fromOscBundle works with multiple messages"] = ->
    oscbundle = osc.toOscString "#bundle"
    osctimetag = osc.toIntegerBuffer 0, "UInt64"
    oscaddr1 = osc.toOscString "/addr"
    osctype1 = osc.toOscString ","
    oscmessage1 = osc.concatenateBuffers [oscaddr1, osctype1]
    osclen1 = osc.toIntegerBuffer oscmessage1.length
    oscaddr2 = osc.toOscString "/addr2"
    osctype2 = osc.toOscString ","
    oscmessage2 = osc.concatenateBuffers [oscaddr2, osctype2]
    osclen2 = osc.toIntegerBuffer oscmessage2.length
    buffer = osc.concatenateBuffers [oscbundle, osctimetag, osclen1, oscmessage1, osclen2, oscmessage2]
    translate = osc.fromOscBundle buffer
    assert.strictEqual translate?.timetag, 0
    assert.strictEqual translate?.elements?.length, 2
    assert.strictEqual translate?.elements?[0]?.address, "/addr"
    assert.strictEqual translate?.elements?[1]?.address, "/addr2"
    
    
exports["fromOscBundle works with nested bundles"] = ->
    oscbundle = osc.toOscString "#bundle"
    osctimetag = osc.toIntegerBuffer 0, "UInt64"
    oscaddr1 = osc.toOscString "/addr"
    osctype1 = osc.toOscString ","
    oscmessage1 = osc.concatenateBuffers [oscaddr1, osctype1]
    osclen1 = osc.toIntegerBuffer oscmessage1.length
    oscbundle2 = osc.toOscString "#bundle"
    osctimetag2 = osc.toIntegerBuffer 0, "UInt64"
    oscmessage2 = osc.concatenateBuffers [oscbundle2, osctimetag2]
    osclen2 = osc.toIntegerBuffer oscmessage2.length
    buffer = osc.concatenateBuffers [oscbundle, osctimetag, osclen1, oscmessage1, osclen2, oscmessage2]
    translate = osc.fromOscBundle buffer
    assert.strictEqual translate?.timetag, 0
    assert.strictEqual translate?.elements?.length, 2
    assert.strictEqual translate?.elements?[0]?.address, "/addr"
    assert.strictEqual translate?.elements?[1]?.timetag, 0
       
exports["fromOscBundle works with non-understood messages"] = ->
    oscbundle = osc.toOscString "#bundle"
    osctimetag = osc.toIntegerBuffer 0, "UInt64"
    oscaddr1 = osc.toOscString "/addr"
    osctype1 = osc.toOscString ","
    oscmessage1 = osc.concatenateBuffers [oscaddr1, osctype1]
    osclen1 = osc.toIntegerBuffer oscmessage1.length
    oscaddr2 = osc.toOscString "/addr2"
    osctype2 = osc.toOscString ",α"
    oscmessage2 = osc.concatenateBuffers [oscaddr2, osctype2]
    osclen2 = osc.toIntegerBuffer oscmessage2.length
    buffer = osc.concatenateBuffers [oscbundle, osctimetag, osclen1, oscmessage1, osclen2, oscmessage2]
    translate = osc.fromOscBundle buffer
    assert.strictEqual translate?.timetag, 0
    assert.strictEqual translate?.elements?.length, 1
    assert.strictEqual translate?.elements?[0]?.address, "/addr"

exports["fromOscBundle fails with bad bundle ID"] = ->
    oscbundle = osc.toOscString "#blunder"
    assert.throws -> osc.fromOscBundle oscbundle

exports["fromOscBundle fails with ridiculous sizes"] = ->
    oscbundle = osc.concatenateBuffers [
        osc.toOscString "#bundle"
        osc.toIntegerBuffer 1234567, "Int64"
        osc.toIntegerBuffer 999999
    ]
    assert.throws -> osc.fromOscBundle oscbundle

roundTripMessage = (args) ->
    oscMessage = {
        address : "/addr"
        arguments : args
    }
    roundTrip = osc.fromOscMessage (osc.toOscMessage oscMessage), true
    assert.strictEqual roundTrip?.address, "/addr"
    assert.strictEqual roundTrip?.arguments?.length, args.length
    for i in [0...args.length]
        comp = if args[i]?.value? then args[i].value else args[i]
        assert.strictEqual roundTrip?.arguments?[i]?.type, args[i].type if args[i]?.type?
        if Buffer.isBuffer comp
            for j in [0...comp.length]
                assert.strictEqual roundTrip?.arguments?[i]?.value?[j], comp[j] 
        else
            assert.strictEqual roundTrip?.arguments?[i]?.value, comp

exports["toOscArgument fails when given bogus type"] = ->
    assert.throws -> osc.toOscArgument "bleh", "bogus"

# we tested fromOsc* manually, so just use roundtrip testing for toOsc*
exports["toOscMessage with no arguments works"] = ->
    roundTripMessage []
    
exports["toOscMessage with null argument throws"] = ->
    assert.throws -> osc.toOscMessage {address : "/addr", arguments : [null]}

exports["toOscMessage with string argument works"] = ->
    roundTripMessage ["strr"]

buffeq = (buff, exp_buff) ->
    assert.strictEqual buff.length, exp_buff.length
    for i in [0...exp_buff.length]
        assert.equal buff[i], exp_buff[i]

exports["toOscMessage with bad layout works"] = ->
    oscMessage = {
        address : "/addr"
        arguments : [
            "strr"
        ]
    }
    roundTrip = osc.fromOscMessage (osc.toOscMessage oscMessage), true
    assert.strictEqual roundTrip?.address, "/addr"
    assert.strictEqual roundTrip?.arguments?.length, 1
    assert.strictEqual roundTrip?.arguments?[0]?.value, "strr"

exports["toOscMessage with single numeric argument works"] = ->
    oscMessage = {
        address : "/addr"
        arguments : 13
    }
    roundTrip = osc.fromOscMessage (osc.toOscMessage oscMessage)
    assert.strictEqual roundTrip?.address, "/addr"
    assert.strictEqual roundTrip?.arguments?.length, 1
    assert.strictEqual roundTrip?.arguments?[0]?.value, 13
    assert.strictEqual roundTrip?.arguments?[0]?.type, "float"
    
exports["toOscMessage with single blob argument works"] = ->
    buff = new Buffer 18
    oscMessage = {
        address : "/addr"
        arguments : buff
    }
    roundTrip = osc.fromOscMessage (osc.toOscMessage oscMessage)
    assert.strictEqual roundTrip?.address, "/addr"
    assert.strictEqual roundTrip?.arguments?.length, 1
    buffeq roundTrip?.arguments?[0]?.value, buff
    assert.strictEqual roundTrip?.arguments?[0]?.type, "blob"
    
exports["toOscMessage with single string argument works"] = ->
    oscMessage = {
        address : "/addr"
        arguments : "strr"
    }
    roundTrip = osc.fromOscMessage (osc.toOscMessage oscMessage)
    assert.strictEqual roundTrip?.address, "/addr"
    assert.strictEqual roundTrip?.arguments?.length, 1
    assert.strictEqual roundTrip?.arguments?[0]?.value, "strr"   
    assert.strictEqual roundTrip?.arguments?[0]?.type, "string"
    
exports["toOscMessage with integer argument works"] = ->
    roundTripMessage [8]
    
    
exports["toOscMessage with buffer argument works"] = ->
    # buffer will have random contents, but that's okay.
    roundTripMessage [new Buffer 16]
    
    
exports["toOscMessage with float argument works"] = ->
    roundTripMessage [{value : 6, type : "float"}]
    
exports["toOscMessage just a string works"] = ->
    message = osc.fromOscMessage osc.toOscMessage "bleh"
    assert.strictEqual message.address, "bleh"
    assert.strictEqual message.arguments.length, 0
    
exports["toOscMessage with multiple arguments works"] = ->
    roundTripMessage ["str", 7, (new Buffer 30), 6]

exports["toOscMessage with integer argument works"] = ->
    roundTripMessage [{value : 7, type: "integer"}]
    
exports["toOscMessage fails with no address"] = ->
    assert.throws -> osc.toOscMessage {arguments : []}    
    
toOscMessageThrowsHelper = (arg) ->
    assert.throws -> osc.toOscMessage(
        address : "/addr"
        arguments : [arg]
    )
    
exports["toOscMessage fails when string type is specified but wrong"] = ->
    toOscMessageThrowsHelper(
        value : 7
        type : "string"
    )

exports["toOscMessage fails when integer type is specified but wrong"] = ->
    toOscMessageThrowsHelper(
        value : "blah blah"
        type : "integer"
    )
    
exports["toOscMessage fails when float type is specified but wrong"] = ->
    toOscMessageThrowsHelper(
        value : "blah blah"
        type : "float"
    )
    
exports["toOscMessage fails when blob type is specified but wrong"] = ->
    toOscMessageThrowsHelper(
        value : "blah blah"
        type : "blob"
    )

exports["toOscMessage fails argument is a random type"] = ->
    toOscMessageThrowsHelper(
        random_field : 42
        "is pretty random" : 888
    )

roundTripBundle = (elems) ->
    oscMessage = {
        timetag : 0
        elements : elems
    }
    roundTrip = osc.fromOscBundle (osc.toOscBundle oscMessage), true
    assert.strictEqual roundTrip?.timetag, 0
    assert.strictEqual roundTrip?.elements?.length, elems.length
    for i in [0...elems.length]
        assert.strictEqual roundTrip?.elements?[i]?.timetag, elems[i].timetag
        assert.strictEqual roundTrip?.elements?[i]?.address, elems[i].address
        
exports["toOscBundle with no elements works"] = ->
    roundTripBundle []

exports["toOscBundle with one message works"] = ->
    roundTripBundle [{address : "/addr"}]
    
exports["toOscBundle with nested bundles works"] = ->
    roundTripBundle [{address : "/addr"}, {timetag : 0}]

exports["toOscBundle with bogus packets works"] = ->
    roundTrip = osc.fromOscBundle osc.toOscBundle {
        timetag : 0
        elements : [{timetag : 0}, {maddress : "/addr"}]
    }
    assert.strictEqual roundTrip.elements.length, 1
    assert.strictEqual roundTrip.elements[0].timetag, 0

exports["toOscBundle strict fails without timetags"] = ->
    assert.throws -> osc.toOscBundle {elements :[]}, true
    
exports["identity applyTransform works with single message"] = ->
    testBuffer = osc.toOscString "/message"
    assert.strictEqual (osc.applyTransform testBuffer, (a) -> a), testBuffer

exports["nullary applyTransform works with single message"] = ->
    testBuffer = osc.toOscString "/message"
    assert.strictEqual (osc.applyTransform testBuffer, (a) -> new Buffer 0).length, 0

exports["toOscPacket works when explicitly set to bundle"] = ->
    roundTrip = osc.fromOscBundle osc.toOscPacket {timetag: 0, oscType:"bundle", elements :[]}, true 
    assert.strictEqual roundTrip.elements.length, 0

exports["toOscPacket works when explicitly set to message"] = ->
    roundTrip = osc.fromOscPacket osc.toOscPacket {address: "/bleh", oscType:"message", arguments :[]}, true 
    assert.strictEqual roundTrip.arguments.length, 0
    assert.strictEqual roundTrip.address, "/bleh"

exports["identity applyTransform works with a simple bundle"] = ->
    base = {
        timetag : 0
        elements : [
            {address : "test1"}
            {address : "test2"}
        ]
    }
    transformed = osc.fromOscPacket (osc.applyTransform (osc.toOscPacket base), (a) -> a)

    assert.strictEqual transformed?.timetag, 0
    assert.strictEqual transformed?.elements?.length, base.elements.length
    for i in [0...base.elements.length]
        assert.strictEqual transformed?.elements?[i]?.timetag, base.elements[i].timetag
        assert.strictEqual transformed?.elements?[i]?.address, base.elements[i].address

exports["applyMessageTranformerToBundle fails on bundle without tag"] = ->
    func = osc.applyMessageTranformerToBundle ((a) -> a)
    assert.throws -> func osc.concatenateBuffers [osc.toOscString "#grundle", osc.toIntegerBuffer 0, "Int64"]

exports["addressTransform works with identity"] = ->
    testBuffer = osc.concatenateBuffers [
        osc.toOscString "/message"
        new Buffer "gobblegobblewillsnever\u0000parse blah lbha"
    ]
    transformed = osc.applyTransform testBuffer, osc.addressTransform((a) -> a)
    for i in [0...testBuffer.length]
        assert.equal transformed[i], testBuffer[i]
    
    
exports["addressTransform works with bundles"] = ->
    base = {
        timetag : 0
        elements : [
            {address : "test1"}
            {address : "test2"}
        ]
    }
    transformed = osc.fromOscPacket (osc.applyTransform (osc.toOscPacket base), osc.addressTransform((a) -> "/prelude/" + a))

    assert.strictEqual transformed?.timetag, 0
    assert.strictEqual transformed?.elements?.length, base.elements.length
    for i in [0...base.elements.length]
        assert.strictEqual transformed?.elements?[i]?.timetag, base.elements[i].timetag
        assert.strictEqual transformed?.elements?[i]?.address, "/prelude/" + base.elements[i].address

exports["messageTransform works with identity function for single message"] = ->
    message =
        address: "/addr"
        arguments: []
    buff = osc.toOscPacket message
    buffeq (osc.applyTransform buff, osc.messageTransform (a) -> a), buff
    
    
exports["messageTransform works with bundles"] = ->
    message = {
        timetag : 0
        elements : [
            {address : "test1"}
            {address : "test2"}
        ]
    }
    buff = osc.toOscPacket message
    buffeq (osc.applyTransform buff, osc.messageTransform (a) -> a), buff
    
    
