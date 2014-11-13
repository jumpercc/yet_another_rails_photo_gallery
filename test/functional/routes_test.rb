# encoding: UTF-8
require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "album routes" do
    assert_generates(
      "/album",
      {
        :controller => "album",
        :action => "view",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "view",
      },
      "/album"
    )

    assert_generates(
      "/album/-a-zA-Z0-9_':",
      {
        :controller => "album",
        :action => "view",
        :album => "-a-zA-Z0-9_':",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "view",
        :album => "-a-zA-Z0-9_':",
      },
      "/album/-a-zA-Z0-9_':"
    )

    assert_generates(
      "/album/-a-zA-Z0-9_':/auth",
      {
        :controller => "album",
        :action => "authentify",
        :album => "-a-zA-Z0-9_':",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "authentify",
        :album => "-a-zA-Z0-9_':",
      },
      {
        :path   => "/album/-a-zA-Z0-9_':/auth",
        :method => "post",
      },
    )

    assert_generates(
      "/date",
      {
        :controller => "album",
        :action => "calendar",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "calendar",
      },
      "/date"
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "update",
        :album => "aaa",
        :format => "json",
      },
      {
        :path   => "/album/aaa/update.json",
        :method => "post",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "list_all",
        :format => "json",
      },
      "/album/list_all.json",
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "create",
        :format => "json",
      },
      {
        :path   => "/album/create.json",
        :method => "post",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "delete",
        :album => "aaa",
        :format => "json",
      },
      {
        :path   => "/album/aaa/delete.json",
        :method => "post",
      }
    )

    assert_generates(
      "/album/hidden",
      {
        :controller => "album",
        :action => "hidden_albums",
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "hidden_albums",
      },
      "/album/hidden"
    )
  end

  test "image routes" do
    assert_generates(
      "/date/2014-09-03",
      {
        :controller => "image",
        :action => "by_date",
        :date => "2014-09-03",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "by_date",
        :date => "2014-09-03",
      },
      "/date/2014-09-03"
    )

    assert_generates(
      "/tag/blah",
      {
        :controller => "image",
        :action => "by_tag",
        :tag => "blah",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "by_tag",
        :tag => "blah",
      },
      "/tag/blah"
    )

    assert_generates(
      "/image/alb/imm.jpg.json",
      {
        :controller => "image",
        :action => "view",
        :album => "alb",
        :name => "imm.jpg",
        :format => "json",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "view",
        :album => "alb",
        :name => "imm.jpg",
        :format => "json",
      },
      "/image/alb/imm.jpg.json",
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "update_list",
        :format => "json",
      },
      {
        :path   => "/image/update_list.json",
        :method => "post",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "update",
        :album => "aaa",
        :name => "img_2207.001.jpg",
        :format => "json",
      },
      {
        :path   => "/image/aaa/img_2207.001.jpg/update.json",
        :method => "post",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "delete",
        :name => "img_2207.001.jpg",
        :format => "json",
      },
      {
        :path   => "/image/img_2207.001.jpg/delete.json",
        :method => "post",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "remove_tag",
        :album => "aaa",
        :name => "img_2207.001.jpg",
        :format => "json",
      },
      {
        :path   => "/image/aaa/img_2207.001.jpg/remove_tag.json",
        :method => "post",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "set_as_image_of_a_day",
        :album => "aaa",
        :name => "img_2207.001.jpg",
        :format => "json",
      },
      {
        :path   => "/album/aaa/img_2207.001.jpg/image_of_a_day.json",
        :method => "post",
      }
    )
  end

  test "tag routes" do
    assert_generates(
      "/tag",
      {
        :controller => "tag",
        :action => "list_tags",
      }
    )

    assert_recognizes(
      {
        :controller => "tag",
        :action => "list_tags",
      },
      "/tag"
    )

    assert_recognizes(
      {
        :controller => "tag",
        :action => "create",
      },
      {
        path: "/tag/create",
        method: 'POST',
      }
    )
  end

  test "session routes" do
    assert_recognizes(
      {
        :controller => "session",
        :action => "login",
        :format => "json",
      },
      {
        :path   => "/login.json",
        :method => "post",
      },
    )

    assert_recognizes(
      {
        :controller => "session",
        :action => "logout",
        :format => "json",
      },
      {
        :path   => "/logout.json",
        :method => "post",
      },
    )

    assert_recognizes(
      {
        :controller => "session",
        :action => "set_locale",
        :locale => "en",
      },
      "/settings/locale/en",
    )

    assert_recognizes(
      {
        :controller => "session",
        :action => "set_image_size",
        :image_size => "750x500",
      },
      "/settings/image_size/750x500",
    )

    assert_recognizes(
      {
        :controller => "session",
        :action => "set_lists_order",
        :lists_order => "desc",
        :format => "json",
      },
      "/settings/lists_order/desc.json",
    )
  end

  test "nojs routes" do
    assert_recognizes(
      {
        :controller => "album",
        :action => "view",
        :nojs => true,
      },
      "/nojs/album"
    )

    assert_generates(
      "/nojs/album",
      {
        :controller => "album",
        :action => "view",
        :nojs => true,
      }
    )

    assert_recognizes(
      {
        :controller => "album",
        :action => "view",
        :album => "aaa",
        :nojs => true,
      },
      "/nojs/album/aaa"
    )

    assert_generates(
      "/nojs/album/aaa",
      {
        :controller => "album",
        :action => "view",
        :album => "aaa",
        :nojs => true,
      }
    )

    assert_generates(
      "/nojs/album/alb/image",
      {
        :controller => "image",
        :action => "view_in_list",
        :album => "alb",
        :nojs => true,
        :from => "album",
      }
    )

    assert_recognizes(
      {
        :controller => "image",
        :action => "view_in_list",
        :album => "alb",
        :nojs => true,
        :from => "album",
      },
      "/nojs/album/alb/image",
    )
  end
end
