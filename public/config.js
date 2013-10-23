Xpt.initialize({
    app_title: "Crosspoint",
    init_columns: [
        { title:   "全体のメッセージ"
        , in_filter:  function(p) { return !p.content.match(/#GROUP-ONLY/i); }
        , out_filter: function(p) { return true; }
        , in_map:     function(p) { return p; }
        , out_map:    function(p) { return p; }
        , entry_placeholder: null
        },
        { title:   "あなたのグループ内のメッセージ"
        , in_filter:  function(p) { return p.content.match(/#GROUP-ONLY/i) && Xpt.readFromStorage('group_id') === p.user.group_id; }
        , out_filter: function(p) { return true; }
        , in_map:     function(p) { p.content = p.content.replace(/#GROUP-ONLY/ig, ""); return p; }
        , out_map:    function(p) { p.content += "#GROUP-ONLY"; return p; }
        , entry_placeholder: null
        }
    ]
});
