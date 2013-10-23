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
        { title:   "Q&A (ハッシュタグ#QA)"
        , in_filter:  function(p) { return p.content.match(/#QA/i); }
        , out_filter: function(p) { return true; }
        , in_map:     function(p) { return p; }
        , out_map:    function(p) { p.content += "#QA"; return p; }
        , entry_placeholder: "質問する... / 回答する..."
        },
        { title:   "TA"
        , in_filter:  function(p) { return p.content.match(/#TA/i); }
        , out_filter: function(p) { return true; }
        , in_map:     function(p) { p.content = p.content.replace(/#TA/ig, ""); return p; }
        , out_map:    function(p) { p.content += "#TA"; return p; }
        , entry_placeholder: "質問する... / 回答する..."
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
