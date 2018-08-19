This is an updated version of https://github.com/freitass/todo.txt-vim that
adds repeating TODO items. For this add 'every_N' to an item with a date,
where N is the number of days after which the item is to be repeated.

The new "process" command looks through all the items in your TODO list and
creates new ones as needed.

*Note* Items that have a due date before today will be rescheduled to today.

# Commands

## Sorting tasks:  
* `<localleader>s`   Sort the file  
* `<localleader>s+`  Sort the file on +Projects  
* `<localleader>s@`  Sort the file on @Contexts  
* `<localleader>sd`  Sort the file on dates  
* `<localleader>sdd`  Sort the file on due dates  
* `<localleader>p` Process the file: create new items for repeating items,
  prioritize items that are due today and sort the file
* 
## Edit priority:  

* `<localleader>j`   Decrease the priority of the current line  
* `<localleader>k`   Increase the priority of the current line  
* `<localleader>a`   Add the priority (A) to the current line  
* `<localleader>b`   Add the priority (B) to the current line  
* `<localleader>c`   Add the priority (C) to the current line  

## Date:  
* `<localleader>d`   Set current task's creation date to the current date  

This plugin detects any text file with the name todo.txt or done.txt with an optional prefix that ends in a period (e.g. second.todo.txt, example.done.txt). It also detects a text file named todo.md if you have todo.txt as a file in your vimwiki with markdown syntax.

If you want the help installed, run ":helptags ~/.vim/doc" inside vim after having copied the files.
Then you will be able to get the commands help with: `:h todo.txt`.
