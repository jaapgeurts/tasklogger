import std.stdio;

import core.runtime;
import core.stdcpp.new_;

import qt.widgets.application;

import d2sqlite3;

import mainwindow;

int main()
{
	auto db = Database("tasklogger.db");
	scope(exit) db.close();
	
	scope a = new QApplication(Runtime.cArgs.argc, Runtime.cArgs.argv);

	MainWindow window = cpp_new!MainWindow(null,db);

	window.show();
    return a.exec();

}