import 'package:flutter/material.dart';
import 'package:vista_notes/PocketBase/remoteService.dart';

// ignore: must_be_immutable
class CreateNote extends StatefulWidget {
  CreateNote({
    Key? key,
    this.index,
    this.titleController,
    this.descriptionController,
  }) : super(key: key);

  final formkey = GlobalKey<FormState>();
  final index;
  final titleController;
  final descriptionController;

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  late String title, description;

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("افزودن یادداشت"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 400,
              child: Form(
                  key: widget.formkey,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 9),
                        child: TextFormField(
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration.collapsed(
                              hintText: "موضوع",
                              // filled: true,
                              hintStyle: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold)),
                          autofocus: true,
                          textDirection: TextDirection.rtl,
                          controller: titleController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 1, 15, 9),
                        child: TextFormField(
                          style: const TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w300),
                          maxLines: 30,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration.collapsed(
                              hintText: "...یادداشت کنید",
                              hintStyle: TextStyle(fontSize: 23)),
                          textDirection: TextDirection.rtl,
                          controller: descController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "dsdd";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  )),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addNotes(titleController.text, descController.text)
              .then((value) => Navigator.of(context).pop());
        }
        // {
        //   if (widget.formkey.currentState!.validate()) {
        //     var newNote = Todo(
        //         title: titleController.text, description: descController.text);

        //     Box<Todo> submitDate = Hive.box("todos");

        //     _updateData() {
        //       Todo newData = Todo(
        //         title: titleController.text,
        //         description: descController.text,
        //       );
        //       submitDate.putAt(widget.index, newData);
        //     }

        //     if (widget.todo != null) {
        //       widget.todo!.title = newNote.title;
        //       widget.todo!.description = newNote.description;
        //       Navigator.pop(context);
        //     } else {
        //       await submitDate
        //           .add(newNote)
        //           .then((value) => Navigator.pop(context));
        //     }
        //   } else {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text("لطفا یادداشت خود را بنویسید")));
        //   }
        // },
        ,
        child: const Icon(Icons.check),
      ),
    );
  }
}
