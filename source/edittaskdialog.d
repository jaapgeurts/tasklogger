module edittaskdialog;

import std.stdio;
import std.conv;

import core.stdcpp.new_;
import qt.core.object;
import qt.core.string;
import qt.core.variant;
import qt.core.datetime;
import qt.helpers;

import qt.widgets.ui;
import qt.widgets.dialog;
import qt.widgets.widget;
import qt.widgets.label;

import qt.widgets.pushbutton;

import taskmodel;


class EditTaskDialog : QDialog {

    mixin(Q_OBJECT_D);

    this(QWidget parent = null) {

        super(parent);

        this.ui = cpp_new!(typeof(*ui));

        ui.setupUi(this);

        connect(this.signal!("accepted"), this.slot!("onAccepted"));

    }

    ~this() {
        cpp_delete(ui);
    }

    void setTaskItem(Task item) {
        taskItem = item;
        ui.leDescription.setText(QString(item.description));
    }

    @QSlot void onAccepted() {
        taskItem.description = ui.leDescription.text.toUtf8().data.to!string;
        writeln("Accepted: ", taskItem.description);
    }

private:
    UIStruct!"edittaskdialog.ui"* ui;

    Task taskItem;

}
