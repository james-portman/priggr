$ ->
    sjcl.random.startCollectors()

    $.each hljs.listLanguages(), (i, lang) ->
        $('#syntaxchoice').append("<option>#{lang}</option>")

    $('body').on('click', '#submitpaste', doPaste)

doPaste = (event) ->
    console.log("in doPaste")
    event.preventDefault()

    paste = $('#paste').val()

    if paste.trim()
        console.log()


encrypt = (content) ->
    console.log("in encrypt")

makeKey = (entropy) ->
    entropy = Math.ceil(entropy / 6) * 6
    key = sjcl.bitArray.clamp(sjcl.random.randomWords(Math.ceil(entropy / 32), 0), entropy)
    return sjcl.codec.base64.fromBits(key, 0).replace(/\=+$/, '').replace(/\//, '-')

