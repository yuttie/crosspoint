var Xpt = (function() {
    "use strict";

    var HASHTAG_REGEXP = /##?([\u0030-\u0039\u0041-\u005a\u0061-\u007a\u00aa-\u00aa\u00b2-\u00b3\u00b5-\u00b5\u00b9-\u00ba\u00bc-\u00be\u00c0-\u00d6\u00d8-\u00f6\u00f8-\u02c1\u02c6-\u02d1\u02e0-\u02e4\u02ec-\u02ec\u02ee-\u02ee\u0370-\u0374\u0376-\u0377\u037a-\u037d\u0386-\u0386\u0388-\u038a\u038c-\u038c\u038e-\u03a1\u03a3-\u03f5\u03f7-\u0481\u048a-\u0527\u0531-\u0556\u0559-\u0559\u0561-\u0587\u05d0-\u05ea\u05f0-\u05f2\u0620-\u064a\u0660-\u0669\u066e-\u066f\u0671-\u06d3\u06d5-\u06d5\u06e5-\u06e6\u06ee-\u06fc\u06ff-\u06ff\u0710-\u0710\u0712-\u072f\u074d-\u07a5\u07b1-\u07b1\u07c0-\u07ea\u07f4-\u07f5\u07fa-\u07fa\u0800-\u0815\u081a-\u081a\u0824-\u0824\u0828-\u0828\u0840-\u0858\u08a0-\u08a0\u08a2-\u08ac\u0904-\u0939\u093d-\u093d\u0950-\u0950\u0958-\u0961\u0966-\u096f\u0971-\u0977\u0979-\u097f\u0985-\u098c\u098f-\u0990\u0993-\u09a8\u09aa-\u09b0\u09b2-\u09b2\u09b6-\u09b9\u09bd-\u09bd\u09ce-\u09ce\u09dc-\u09dd\u09df-\u09e1\u09e6-\u09f1\u09f4-\u09f9\u0a05-\u0a0a\u0a0f-\u0a10\u0a13-\u0a28\u0a2a-\u0a30\u0a32-\u0a33\u0a35-\u0a36\u0a38-\u0a39\u0a59-\u0a5c\u0a5e-\u0a5e\u0a66-\u0a6f\u0a72-\u0a74\u0a85-\u0a8d\u0a8f-\u0a91\u0a93-\u0aa8\u0aaa-\u0ab0\u0ab2-\u0ab3\u0ab5-\u0ab9\u0abd-\u0abd\u0ad0-\u0ad0\u0ae0-\u0ae1\u0ae6-\u0aef\u0b05-\u0b0c\u0b0f-\u0b10\u0b13-\u0b28\u0b2a-\u0b30\u0b32-\u0b33\u0b35-\u0b39\u0b3d-\u0b3d\u0b5c-\u0b5d\u0b5f-\u0b61\u0b66-\u0b6f\u0b71-\u0b77\u0b83-\u0b83\u0b85-\u0b8a\u0b8e-\u0b90\u0b92-\u0b95\u0b99-\u0b9a\u0b9c-\u0b9c\u0b9e-\u0b9f\u0ba3-\u0ba4\u0ba8-\u0baa\u0bae-\u0bb9\u0bd0-\u0bd0\u0be6-\u0bf2\u0c05-\u0c0c\u0c0e-\u0c10\u0c12-\u0c28\u0c2a-\u0c33\u0c35-\u0c39\u0c3d-\u0c3d\u0c58-\u0c59\u0c60-\u0c61\u0c66-\u0c6f\u0c78-\u0c7e\u0c85-\u0c8c\u0c8e-\u0c90\u0c92-\u0ca8\u0caa-\u0cb3\u0cb5-\u0cb9\u0cbd-\u0cbd\u0cde-\u0cde\u0ce0-\u0ce1\u0ce6-\u0cef\u0cf1-\u0cf2\u0d05-\u0d0c\u0d0e-\u0d10\u0d12-\u0d3a\u0d3d-\u0d3d\u0d4e-\u0d4e\u0d60-\u0d61\u0d66-\u0d75\u0d7a-\u0d7f\u0d85-\u0d96\u0d9a-\u0db1\u0db3-\u0dbb\u0dbd-\u0dbd\u0dc0-\u0dc6\u0e01-\u0e30\u0e32-\u0e33\u0e40-\u0e46\u0e50-\u0e59\u0e81-\u0e82\u0e84-\u0e84\u0e87-\u0e88\u0e8a-\u0e8a\u0e8d-\u0e8d\u0e94-\u0e97\u0e99-\u0e9f\u0ea1-\u0ea3\u0ea5-\u0ea5\u0ea7-\u0ea7\u0eaa-\u0eab\u0ead-\u0eb0\u0eb2-\u0eb3\u0ebd-\u0ebd\u0ec0-\u0ec4\u0ec6-\u0ec6\u0ed0-\u0ed9\u0edc-\u0edf\u0f00-\u0f00\u0f20-\u0f33\u0f40-\u0f47\u0f49-\u0f6c\u0f88-\u0f8c\u1000-\u102a\u103f-\u1049\u1050-\u1055\u105a-\u105d\u1061-\u1061\u1065-\u1066\u106e-\u1070\u1075-\u1081\u108e-\u108e\u1090-\u1099\u10a0-\u10c5\u10c7-\u10c7\u10cd-\u10cd\u10d0-\u10fa\u10fc-\u1248\u124a-\u124d\u1250-\u1256\u1258-\u1258\u125a-\u125d\u1260-\u1288\u128a-\u128d\u1290-\u12b0\u12b2-\u12b5\u12b8-\u12be\u12c0-\u12c0\u12c2-\u12c5\u12c8-\u12d6\u12d8-\u1310\u1312-\u1315\u1318-\u135a\u1369-\u137c\u1380-\u138f\u13a0-\u13f4\u1401-\u166c\u166f-\u167f\u1681-\u169a\u16a0-\u16ea\u16ee-\u16f0\u1700-\u170c\u170e-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176c\u176e-\u1770\u1780-\u17b3\u17d7-\u17d7\u17dc-\u17dc\u17e0-\u17e9\u17f0-\u17f9\u1810-\u1819\u1820-\u1877\u1880-\u18a8\u18aa-\u18aa\u18b0-\u18f5\u1900-\u191c\u1946-\u196d\u1970-\u1974\u1980-\u19ab\u19c1-\u19c7\u19d0-\u19da\u1a00-\u1a16\u1a20-\u1a54\u1a80-\u1a89\u1a90-\u1a99\u1aa7-\u1aa7\u1b05-\u1b33\u1b45-\u1b4b\u1b50-\u1b59\u1b83-\u1ba0\u1bae-\u1be5\u1c00-\u1c23\u1c40-\u1c49\u1c4d-\u1c7d\u1ce9-\u1cec\u1cee-\u1cf1\u1cf5-\u1cf6\u1d00-\u1dbf\u1e00-\u1f15\u1f18-\u1f1d\u1f20-\u1f45\u1f48-\u1f4d\u1f50-\u1f57\u1f59-\u1f59\u1f5b-\u1f5b\u1f5d-\u1f5d\u1f5f-\u1f7d\u1f80-\u1fb4\u1fb6-\u1fbc\u1fbe-\u1fbe\u1fc2-\u1fc4\u1fc6-\u1fcc\u1fd0-\u1fd3\u1fd6-\u1fdb\u1fe0-\u1fec\u1ff2-\u1ff4\u1ff6-\u1ffc\u2070-\u2071\u2074-\u2079\u207f-\u2089\u2090-\u209c\u2102-\u2102\u2107-\u2107\u210a-\u2113\u2115-\u2115\u2119-\u211d\u2124-\u2124\u2126-\u2126\u2128-\u2128\u212a-\u212d\u212f-\u2139\u213c-\u213f\u2145-\u2149\u214e-\u214e\u2150-\u2189\u2460-\u249b\u24ea-\u24ff\u2776-\u2793\u2c00-\u2c2e\u2c30-\u2c5e\u2c60-\u2ce4\u2ceb-\u2cee\u2cf2-\u2cf3\u2cfd-\u2cfd\u2d00-\u2d25\u2d27-\u2d27\u2d2d-\u2d2d\u2d30-\u2d67\u2d6f-\u2d6f\u2d80-\u2d96\u2da0-\u2da6\u2da8-\u2dae\u2db0-\u2db6\u2db8-\u2dbe\u2dc0-\u2dc6\u2dc8-\u2dce\u2dd0-\u2dd6\u2dd8-\u2dde\u2e2f-\u2e2f\u3005-\u3007\u3021-\u3029\u3031-\u3035\u3038-\u303c\u3041-\u3096\u309d-\u309f\u30a1-\u30fa\u30fc-\u30ff\u3105-\u312d\u3131-\u318e\u3192-\u3195\u31a0-\u31ba\u31f0-\u31ff\u3220-\u3229\u3248-\u324f\u3251-\u325f\u3280-\u3289\u32b1-\u32bf\u3400-\u4db5\u4e00-\u9fcc\ua000-\ua48c\ua4d0-\ua4fd\ua500-\ua60c\ua610-\ua62b\ua640-\ua66e\ua67f-\ua697\ua6a0-\ua6ef\ua717-\ua71f\ua722-\ua788\ua78b-\ua78e\ua790-\ua793\ua7a0-\ua7aa\ua7f8-\ua801\ua803-\ua805\ua807-\ua80a\ua80c-\ua822\ua830-\ua835\ua840-\ua873\ua882-\ua8b3\ua8d0-\ua8d9\ua8f2-\ua8f7\ua8fb-\ua8fb\ua900-\ua925\ua930-\ua946\ua960-\ua97c\ua984-\ua9b2\ua9cf-\ua9d9\uaa00-\uaa28\uaa40-\uaa42\uaa44-\uaa4b\uaa50-\uaa59\uaa60-\uaa76\uaa7a-\uaa7a\uaa80-\uaaaf\uaab1-\uaab1\uaab5-\uaab6\uaab9-\uaabd\uaac0-\uaac0\uaac2-\uaac2\uaadb-\uaadd\uaae0-\uaaea\uaaf2-\uaaf4\uab01-\uab06\uab09-\uab0e\uab11-\uab16\uab20-\uab26\uab28-\uab2e\uabc0-\uabe2\uabf0-\uabf9\uac00-\ud7a3\ud7b0-\ud7c6\ud7cb-\ud7fb\uf900-\ufa6d\ufa70-\ufad9\ufb00-\ufb06\ufb13-\ufb17\ufb1d-\ufb1d\ufb1f-\ufb28\ufb2a-\ufb36\ufb38-\ufb3c\ufb3e-\ufb3e\ufb40-\ufb41\ufb43-\ufb44\ufb46-\ufbb1\ufbd3-\ufd3d\ufd50-\ufd8f\ufd92-\ufdc7\ufdf0-\ufdfb\ufe70-\ufe74\ufe76-\ufefc\uff10-\uff19\uff21-\uff3a\uff41-\uff5a\uff66-\uffbe\uffc2-\uffc7\uffca-\uffcf\uffd2-\uffd7\uffda-\uffdc]+)/g;

    function escapeRegexp(src) {
        return src.replace(/[-\\^$*+?.()|[\]{}]/g, '\\$&');
    };

    function constructColumnElement(col_def, index) {
        return $("<div>", { "class": "column", id: "column-" + index }).append([
                   $("<div>", { "class": "column-header"
                              , draggable: "true" }).append([
                       $("<span>", { "class": "column-title" }).text(col_def.title),
                       $("<span>", { "class": "column-close-button" }).text("×")]),
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

        var close_button = header.find(".column-close-button");
        close_button.on("click", function() {
            // FIXME: Removing the column element isn't sufficient, we need to
            // remove the col_def from the columns variable.
            $(this).parents(".column").remove();
        });
        if (!col_def.removable) {
            close_button.css("display", "none");
        }

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

        return col;
    }

    function addColumnForHashtag(hashtag) {
        addColumn(
            { title:   "ハッシュタグ: " + hashtag
            , in_filter:  function(p) { return p.content.match(new RegExp(escapeRegexp(hashtag), "i")); }
            , out_filter: function(p) { return true; }
            , in_map:     function(p) { return p; }
            , out_map:    function(p) { p.content += hashtag; return p; }
            , entry_placeholder: null
            , removable: true
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
        var post_elem =
            $("<div>", { "class": "post" }).append([
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
                    .text(post.content)]);
        var content_elem = post_elem.find(".content");
        content_elem.html(function(_, html) {
            return html.replace(HASHTAG_REGEXP, function(hashtag) {
                return '<span class="hashtag">' + hashtag + '</span>';
            });
        });
        content_elem.find(".hashtag").on("click", function(e) {
            addColumnForHashtag($(this).text());
        });

        return post_elem;
    }

    var new_posts = [];
    function showPost(post, col_def, i) {
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
    }

    function showPostAllColumns(post) {
        columns.forEach(function(col_def, i) {
            showPost(post, col_def, i);
        });
    }

    var ws = null;
    var posts = [];
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
            var latest_post = posts[posts.length - 1];
            ws.send(JSON.stringify(
                { type: "need-archived-posts"
                , since: latest_post ? latest_post.post_id : null }));
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
                showPostAllColumns(msg);
                posts.push(msg);
            }
            else if (msg.type === "archived-posts") {
                msg.posts.forEach(showPostAllColumns);
                posts = posts.concat(msg.posts);
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
