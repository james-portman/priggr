$ ->
    $.each hljs.listLanguages(), (i, lang) ->
        $('#syntaxchoice').append("<option>#{lang}</option>")

    $('body').on('click', '#submitpaste', doPaste)

    pasteid = window.location.search
    if pasteid != ""
        pasteid = pasteid.replace("?", "")
        getPaste(pasteid)

getPaste = (pasteid) ->
    console.log("in getPaste with ID #{pasteid}")
    $.getJSON("/p/#{pasteid}").done (data) ->
        cleandata = data['paste']
        cleandata = cleandata.replace(/>/g, '&gt;')
        cleandata = cleandata.replace(/</g, '&lt;')
        cleandata = cleandata.replace(/"/g, '&quot;')

        $('#pastewell').append("<pre><code class=\"#{data['syntax']}\">#{cleandata}</code></pre>")
        $('#pastewell').each (i, e) ->
            hljs.highlightBlock(e)
        $('#pastewell').show()

        $('#syntaxchoice').val(data['syntax'])
        $('#expires').val(data['expires'])
        $('#paste').val(data['paste'])

doPaste = (event) ->
    console.log("in doPaste")
    event.preventDefault()

    postBody = {}
    postBody["paste"] = $('#paste').val().trim()
    postBody["syntax"] = $('#syntaxchoice').val()
    postBody["expires"] = $('#expires').val()

    $.ajax({
        type: "POST",
        url: "http://localhost:8998/p",
        contentType: "application/json",
        dataType: "json",
        data: JSON.stringify(postBody)
    }).complete (res, err) ->
        console.log(res)
        if not err == "" or err == "error"
            console.log("Error posting request!")
            return
        if res.responseJSON['message'] == 'ok'
            window.location.assign("?#{res.responseJSON['id']}")
        else
            console.log(res.responseJSON['message'])
