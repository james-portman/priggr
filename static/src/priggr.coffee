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
    $.getJSON("/p/#{pasteid}")
    .done (data) ->
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
    .fail () ->
        displayAlert("Paste not found.")

doPaste = (event) ->
    console.log("in doPaste")
    event.preventDefault()

    postBody = {}
    postBody["paste"] = $('#paste').val().trim()
    postBody["syntax"] = $('#syntaxchoice').val()
    postBody["expires"] = $('#expires').val()

    if postBody["paste"] == ""
        displayAlert("You didn't enter anything to paste?")
        return

    $.ajax({
        type: "POST",
        url: "/p",
        contentType: "application/json",
        dataType: "json",
        data: JSON.stringify(postBody)
    }).complete (res, err) ->
        console.log(res)
        if not err == "" or err == "error"
            displayAlert("Error posting request!")
            return
        if res.responseJSON['message'] == 'ok'
            window.location.assign("?#{res.responseJSON['id']}")
        else
            displayAlert("Error posting request: #{res.responseJSON['message']}")


displayAlert = (msg) ->
    $('#pasteError').html("")
    $('#pasteError').append(msg)
    $('#pasteError').fadeIn(500).delay(3000).fadeOut(800)
