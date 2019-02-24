#include "usermanager.hh"
#include <QDebug>
#include <QFile>

UserManager::UserManager(QObject *parent) : QObject(parent)
{

}

// Get the saved config file contents
QString UserManager::getPreviousConfig()
{
    QString filename = "config";
    QFile file(filename);
    QString config;
    if ( file.open(QIODevice::ReadOnly) )
    {
        QTextStream stream( &file );
        config = stream.readAll();
    }
    else {
        return "{\"data_views\":[{\"col\":0,\"data_type\":\"Current value\",\"graph_type\":\"Temperature\",\"row\":0}],\"row_counts\":[1]}";
    }
    file.close();
    return config;
}

// Write given config to config file
void UserManager::saveConfig(QString config)
{
    qDebug() << "Saving config " << config;

    QString filename = "config";
    QFile file(filename);
    if ( file.open(QIODevice::ReadWrite | QIODevice::Truncate | QIODevice::Text))
    {
        QTextStream stream( &file );
        stream << config << endl;
    }
    file.close();
}
