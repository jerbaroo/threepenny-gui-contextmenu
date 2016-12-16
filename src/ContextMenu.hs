module ContextMenu (
    contextMenu
    ) where

import qualified Graphics.UI.Threepenny       as UI
import           Graphics.UI.Threepenny.Core

menuStyle = [
        ("background",      "#FFF"),
        ("border",          "1px solid #CCC"),
        ("border-radius",   "3px"),
        ("color",           "#333"),
        ("display",         "none"),
        ("list-style-type", "none"),
        ("margin",          "0"),
        ("padding-left",    "0"),
        ("position",        "absolute")
    ]

menuItemStyle = [
        ("cursor",  "pointer"),
        ("padding", "8px 12px")
    ]

rmTargetStyle = [
        ("height",   "0"),
        ("left",     "0"),
        ("position", "absolute"),
        ("top",      "0"),
        ("width",    "0")
    ]

-- TODO
--   Close menu on menu item click.

-- Summary of how the menu operates:
--
-- on source element right click:
--   set rmTarget size to 100vw x 100vh
--   set menu to display
-- on menu item or rmTarget click:
--   set rmTarget size to 0 x 0
--   set menu to display none
-- on menu item click:
--   run UI action

-- |Attaches a custom context menu to an element.
contextMenu :: [(String, [UI b])] -> Element -> UI ()
contextMenu items source = do
    rmTarget <- UI.div # set style rmTargetStyle
    menu <- UI.ul # set style menuStyle
    element source #+ [element rmTarget, element menu]
    let close = do
            element menu     # set style [("display", "none")]
            element rmTarget # set style [("width", "0"), ("height", "0")]
    element menu #+ map (menuItem close) items
    -- Display the menu at mouse on a contextmenu event.
    on UI.contextmenu source $ \(x, y) -> do
        liftIO $ putStrLn "context event fired"
        element rmTarget # set style
            [("width", "100vw"), ("height", "100vh")]
        element menu # set style
            [("left", show x ++ "px"), ("top", show y ++ "px"),
             ("display", "block")]
    -- Hide the menu when the screen is clicked elsewhere.
    on UI.mousedown rmTarget $ const $ do
        close
        liftIO $ putStrLn "rmTarget clicked"
    preventDefaultContextMenu source

-- |Returns a menu item element from a string.
menuItem :: UI a -> (String, [UI b]) -> UI Element
menuItem close (item, f) = do
    itemEl <- UI.li # set UI.text item # set style menuItemStyle
    on UI.hover itemEl $ const $
        element itemEl # set style [("background-color", "#DEF")]
    on UI.leave itemEl $ const $
        element itemEl # set style [("background-color", "inherit")]
    on UI.click itemEl $ const $ do
        liftIO $ putStrLn "event clicked"
        sequence_ f
    return itemEl

preventDefaultClass = "__prevent-default-context-menu"

-- |Prevents the default action on a contextmenu event.
preventDefaultContextMenu :: Element -> UI ()
preventDefaultContextMenu el = do
    element el # set UI.class_ preventDefaultClass
    runFunction $ ffi
        "$(%1).bind('contextmenu', e => e.preventDefault())"
        ("." ++ preventDefaultClass)
