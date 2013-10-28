var Xpt = (function() {
    "use strict";

    function constructColumnElement(col_def, index) {
        return $("<div>", { "class": "column", id: "column-" + index }).append([
                   $("<div>", { "class": "column-header"
                              , draggable: "true" })
                       .text(col_def.title),
                   $("<div>", { "class": "column-view" }).append([
                       $("<textarea>", { "class": "comment-entry"
                                       , placeholder: col_def.entry_placeholder || "書き込む..." })])]);
    }

    var columns = [];
    function addColumn(col_def) {
        var index = columns.length;
        columns.push(col_def);

        var col = constructColumnElement(col_def, index);
        col.appendTo("#column-container");

        var header = col.find(".column-header");
        header.on("dragstart", function(e) {
            var target = $(this).parent();
            setTimeout(function() {
                // hide the target column after getting a drag image of it
                target.addClass("drag-target");
            }, 0);
            var dt = e.originalEvent.dataTransfer;
            dt.effectAllowed = "move";
            dt.setData("application/element-id", target.attr("id"));
            dt.setDragImage(target[0],
                            e.originalEvent.clientX - target.offset().left,
                            e.originalEvent.clientY - target.offset().top);
            var dummy = $("<div>", { "class": "column", id: "dummy-column" });
            dummy.insertAfter(target);
            dummy.on("dragover", function(e) {
                e.originalEvent.dataTransfer.dropEffect = "move";
                e.preventDefault();
            });
            dummy.on("drop", function(e) {
                var column_id = e.originalEvent.dataTransfer.getData("application/element-id");
                var target = $("#" + column_id);
                target.insertBefore("#dummy-column");
                e.stopPropagation();
            });
        });
        col.on("dragover", function(e) {
            var x = e.originalEvent.clientX;
            var zoneLeft = $(this).offset().left;
            var zoneCenterX = zoneLeft + $(this).outerWidth() / 2;
            if (x >= zoneCenterX) {
                $("#dummy-column").insertAfter($(this));
            }
            else {
                $("#dummy-column").insertBefore($(this));
            }
            e.originalEvent.dataTransfer.dropEffect = "move";
            e.preventDefault();
        });
        col.on("drop", function(e) {
            var column_id = e.originalEvent.dataTransfer.getData("application/element-id");
            var target = $("#" + column_id);
            target.insertBefore("#dummy-column");
            e.stopPropagation();
        });
        col.on("dragend", function(e) {
            $("#dummy-column").remove();
            $(".column").removeClass("drag-target");
        });

        var entry = col.find(".comment-entry");
        entry.on('keypress', function(e) {
            if (!e.ctrlKey && e.which === 13) {
                // send if the content is not empty
                var s = $(this).val();
                if (s.length > 0) {
                    var msg = { 'type': 'post', 'content': s };
                    if (col_def.out_filter(msg)) {
                        send_message_with_user_id(col_def.out_map(msg), function() { entry.val(''); });
                    }
                }
                e.preventDefault();
            }
            else if (e.which === 10 || (e.ctrlKey && e.which === 13)) {
                // insert a linebreak
                var s = $(this).val();
                var start = this.selectionStart;
                var end = this.selectionEnd;
                $(this).val(s.slice(0, start) + "\n" + s.slice(end));
                this.selectionStart = start + 1;
                this.selectionEnd = start + 1;
            }
        });
    }

    function updateSlideClasses() {
        $('.slide.current').prevAll('.slide').removeClass('prev left');
        $('.slide.current').nextAll('.slide').removeClass('next right');

        $('.slide.current').prevAll('.slide').addClass('left');
        $('.slide.current').nextAll('.slide').addClass('right');

        $('.slide.current').prev('.slide').addClass('prev');
        $('.slide.current').next('.slide').addClass('next');
    }

    function goToPrevSlide() {
        if ($('.slide.current').prev('.slide').length > 0) {
            $('.slide.current').removeClass('current');
            $('.slide.prev').addClass('current');
            $('.slide.prev').removeClass('prev left');

            updateSlideClasses();
        }
    }

    function goToNextSlide() {
        if ($('.slide.current').next('.slide').length > 0) {
            $('.slide.current').removeClass('current');
            $('.slide.next').addClass('current');
            $('.slide.next').removeClass('next right');

            updateSlideClasses();
        }
    }

    // Utility functions for handling cookies
    function parseCookies(def) {
        def = def || {};
        var cookies = {};
        $.each(document.cookie.split(";"), function(_, param) {
            var kv = param.split("=");
            var k = decodeURIComponent(kv[0]);
            var v = decodeURIComponent(kv[1]);
            cookies[k] = v;
        });
        return $.extend(true, {}, def, cookies);
    }

    function getCookie(key) {
        $.each(document.cookie.split(";"), function(_, param) {
            var kv = param.split("=");
            if (decodeURIComponent(kv[0]) === key) {
                return decodeURIComponent(kv[1]);
            }
        });
        return null;
    }

    function setCookie(k, v, opts) {
        opts = opts || {};

        var opts_str = "";
        $.each(opts, function(k, v) {
            opts_str += "; " + k + "=" + v;
        });

        document.cookie = encodeURIComponent(k) + "=" + encodeURIComponent(v) + opts_str;
    }

    function removeCookie(k) {
        setCookie(k, "", { expires: "Thu, 01 Jan 1970 00:00:00 GMT" });
    }

    // Set/get the serial numbers of users
    function writeToStorage(key, value) {
        if (window.localStorage) {
            window.localStorage[key] = JSON.stringify(value);
        }

        setCookie(key, JSON.stringify(value));
    }

    function readFromStorage(key) {
        if (window.localStorage && typeof window.localStorage[key] !== "undefined") {
            return JSON.parse(window.localStorage[key]);
        }
        else {
            return JSON.parse(getCookie(key));
        }
    }

    function isInvalid(x) {
        return x === null || typeof x === "undefined";
    }

    function formatInt2(x) {
        return x < 10 ? '0' + x : x.toString();
    }

    function formatFullPostDate(d) {
        return d.getFullYear() + "/"
             + formatInt2(d.getMonth() + 1) + "/"
             + formatInt2(d.getDate())
             + ' '
             + d.getHours() + ":"
             + formatInt2(d.getMinutes()) + ":"
             + formatInt2(d.getSeconds());
    }

    function formatPostDate(d) {
        return d.getHours() + ':' + formatInt2(d.getMinutes());
    }

    function formatScreenName(sn) {
        if (isInvalid(sn)) {
            return "NO NAME";
        }
        else if (sn.length > 20) {
            return sn.slice(0, 20) + "...";
        }
        else {
            return sn;
        }
    }

    function constructPostElement(post) {
        var date = new Date(post.time);
        return $("<div>", { "class": "post" }).append([
                   $("<div>", { "class": "header" }).append([
                       $("<span>", { "class": "number" })
                           .text(post.number),
                       $("<span>", { "class": "screen-name" })
                           .text(formatScreenName(post.user.screen_name)),
                       $("<span>", { "class": "user-id" })
                           .text(post.user.user_id_hashed.slice(0, 8)),
                       $("<span>", { "class": "time"
                                   , title: formatFullPostDate(date) })
                           .text(formatPostDate(date))]),
                   $("<div>", { "class": "content" })
                       .text(post.content.replace(/\#GROUP-ONLY/ig, ""))]);
    }

    var new_posts = [];
    function showPost(post) {
        columns.forEach(function(col_def, i) {
            if (col_def.in_filter(post)) {
                post = col_def.in_map(post);

                var post_elem = constructPostElement(post);
                MathJax.Hub.Queue(["Typeset", MathJax.Hub, post_elem[0]]);

                var col = $("#column-" + i);
                if (post.user.user_id === readFromStorage('user_id')) {
                    col.find(".new_msg_notifier").click();
                    post_elem.insertAfter(col.find(".comment-entry"));
                }
                else {
                    if (typeof new_posts[i] === "undefined") {
                        new_posts[i] = [];
                    }
                    new_posts[i].push(post_elem);
                    if (col.find(".new_msg_notifier").length === 0) {
                        var notifier = $('<div class="new_msg_notifier"></div>');
                        notifier.insertAfter(col.find(".comment-entry"));
                        notifier.on("click", function(e) {
                            new_posts[i].forEach(function(new_post) {
                                new_post.insertAfter(notifier);
                            });
                            new_posts[i] = [];
                            $(this).remove();
                        });
                    }
                    col.find(".new_msg_notifier").text(new_posts[i].length + "件の新着");
                }
            }
        });
    }

    var ws = null;
    var latest_post_id = null;
    function startWebSocket() {
        var hostname = window.location.hostname;
        ws = new WebSocket("ws://" + hostname + ":9090/");

        ws.onopen = function(){
            var uid = readFromStorage('user_id');
            var gid = readFromStorage('group_id');
            console.log("My user ID is: \"" + uid + "\"");
            console.log("My group ID is: \"" + gid + "\"");
            if (isInvalid(uid)) {
                var msg = { type: 'need-both-ids' };
                ws.send(JSON.stringify(msg));
            }
            else if (isInvalid(gid)) {
                var msg = { type: 'need-group-id', 'user_id': uid };
                ws.send(JSON.stringify(msg));
            }
            $('#screen-name-entry').val(readFromStorage('screen_name')).trigger("input");
            $('#student-id-entry').val(readFromStorage('student_id')).trigger("input");
            ws.send(JSON.stringify(
                { type: "need-archived-posts", since: latest_post_id }));
            $("#status").addClass("online");
        };

        ws.onmessage = function(e) {
            var msg = JSON.parse(e.data);
            if (msg.type === "prev") {
                goToPrevSlide();
            }
            else if (msg.type === "next") {
                goToNextSlide();
            }
            else if (msg.type === "post") {
                showPost(msg);
                latest_post_id = msg.post_id;
            }
            else if (msg.type === "archived-posts") {
                msg.posts.forEach(function(post) {
                    showPost(post);
                    latest_post_id = post.post_id;
                });
                $('.new_msg_notifier').click();
            }
            else if (msg.type === "user-id") {
                writeToStorage('user_id', msg.user_id);
            }
            else if (msg.type === "group-id") {
                writeToStorage('group_id', msg.group_id);
            }
            else if(msg.type == "aux-data") {
                $("#student-id-entry").val(msg.student_id);
                $("#screen-name-entry").val(msg.screen_name);
            }
            else if (msg.type === "roles") {
                $("#roles").empty();
                msg.roles.sort().forEach(function(role) {
                    $('<span class="role">' + role + '</span>').appendTo("#roles");
                });
            }
            else if (msg.type === "draw") {
                var ctx = $('.slide.current > canvas.overlay')[0].getContext('2d');
                if (msg.shape === "line") {
                    ctx.strokeStyle = 'black';
                    ctx.lineWidth = 4;
                    ctx.lineCap = 'round';
                    ctx.lineJoin = 'round';

                    var last_pos = msg.from;
                    var pos = msg.to;
                    ctx.moveTo(last_pos.x, last_pos.y);
                    ctx.lineTo(pos.x, pos.y);
                    ctx.stroke();
                }
            }
        };
        ws.onclose = function() {
            $("#status").removeClass("online");
            setTimeout(function() { startWebSocket(); }, 0);
        };
    }

    function send_message_with_user_id(msg, next_fun) {
        var uid = readFromStorage('user_id');
        if (isInvalid(uid)) {
            setTimeout(function() { send_message_with_user_id(msg, next_fun); }, 1000);
        }
        else {
            msg['user_id'] = uid;
            ws.send(JSON.stringify(msg));
            if (typeof next_fun === "function") {
                next_fun();
            }
        }
    }

    function initialize(config) {
        // change the app title when defined
        if (!isInvalid(config.app_title)) {
            $("title").text(config.app_title);
        }

        // add initial columns
        config.init_columns.forEach(addColumn);

        // Automatically focus on the first .comment-entry
        $(".comment-entry").first().focus();

        $.get('slide.html', function(data) {
            $('#view').html(data);

            $('.slide').first().addClass('current');
            $('.slide').append('<canvas class="overlay"></canvas>');
            $.each($('.slide > canvas.overlay'), function(i, canvas) {
                canvas.width = $(canvas).parent().width();
                canvas.height = $(canvas).parent().height();
            });

            updateSlideClasses();
        });

        $('#screen-name-entry').on('input', function(e) {
            var s = $(this).val();
            if (s.length === 0) {
                s = null;
            }
            var msg = { 'type': 'change-screen-name', 'screen_name': s };
            send_message_with_user_id(msg, function() { writeToStorage('screen_name', s); });
        });
        $('#student-id-entry').on('input', function(e) {
            var s = $(this).val();
            if (s.length === 0) {
                s = null;
            }
            var msg = { 'type': 'change-student-id', 'student_id': s };
            send_message_with_user_id(msg, function() { writeToStorage('student_id', s); });
        });

        // update the link for saving an entire HTML as a file
        $('#export-link').on('mousedown', function(e) {
            var html = $('html').clone();
            function prependBaseURL(_, href) {
                return window.location.href.replace(/\/?[^\/]*$/, "/" + href);
            }
            html.find('link[href="normalize.css"]').attr("href", prependBaseURL);
            html.find('link[href="client.css"]').attr("href", prependBaseURL);
            var html_src = html.html();
            var blob = new Blob([html_src], { type: 'text/html' });
            var blob_url = window.URL.createObjectURL(blob);
            $(this).attr("href", blob_url);
        });
        $('#export-link').on('click', function(e) {
            e.preventDefault();
        });

        startWebSocket();
    }

    // return the module
    return {
        initialize: initialize,
        readFromStorage: readFromStorage
    };
})();
