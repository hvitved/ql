using Microsoft.EntityFrameworkCore;
using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Common;
using System.Linq;

namespace EFCoreTests
{
    class Person
    {
        public int Id { get; set; }
        public string Name { get; set; }

        [NotMapped]
        public int Age { get; set; }
    }

    class MyContext : DbContext
    {
        public virtual DbSet<Person> Persons { get; set; }

        public static MyContext GetInstance() => null;
    }

    class Tests
    {
        void FlowSources()
        {
            var p = new Person();
            var id = p.Id;  // Remote flow source
            var name = p.Name;  // Remote flow source
            var age = p.Age;  // Not a remote flow source
        }

        Microsoft.EntityFrameworkCore.Storage.IRawSqlCommandBuilder builder;

        async void SqlExprs(MyContext ctx)
        {
            // Microsoft.EntityFrameworkCore.RelationalDatabaseFacadeExtensions.ExecuteSqlCommand
            ctx.Database.ExecuteSqlCommand("");  // SqlExpr
            await ctx.Database.ExecuteSqlCommandAsync("");  // SqlExpr

            // Microsoft.EntityFrameworkCore.Storage.IRawSqlCommandBuilder.Build
            builder.Build("");  // SqlExpr

            // Microsoft.EntityFrameworkCore.RawSqlString
            new RawSqlString("");  // SqlExpr
            RawSqlString str = "";  // SqlExpr
        }

        void TestDataFlow()
        {
            var taintSource = "tainted";
            var untaintedSource = "untainted";

            Sink(taintSource);  // Tainted
            Sink(new RawSqlString(taintSource));  // Tainted
            Sink((RawSqlString)taintSource);  // Tainted
            Sink((RawSqlString)(FormattableString)$"{taintSource}");  // Tainted, but not reported because conversion operator is in a stub .cs file

            var p1 = new Person { Name = taintSource };
            var p2 = new Person();

            AddPersonToDB(p1);
            AddPersonToDB(p2);

            var ctx = MyContext.GetInstance();
            ctx.Persons.Add(p1);

            var p3 = new Person { Age = 42 };
            ctx.Persons.Add(p3);
            ctx.SaveChanges();
        }

        void AddPersonToDB(Person p)
        {
            var ctx = MyContext.GetInstance();
            ctx.Persons.Add(p);
            ctx.SaveChanges();
        }

        void ReadFirstPersonFromDB()
        {
            var ctx = MyContext.GetInstance();
            Sink(ctx.Persons.First().Id);
            Sink(ctx.Persons.First().Name);
            Sink(ctx.Persons.First().Age);
        }

        void Sink(object @object)
        {
        }
    }
}
