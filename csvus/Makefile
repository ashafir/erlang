ERL ?= erl
APP := csvus

.PHONY: deps

csvus:	templates erlang

erlang:
	./rebar compile apps=csvus

templates:  ebin/base_dtl.beam \
	    ebin/jobs_dtl.beam \
            ebin/sample_dtl.beam

ebin/jobs_dtl.beam: templates/jobs.dtl \
                    templates/queryform \
                    templates/results

ebin/%_dtl.beam: templates/%.dtl
	./cdtl $*

sql:	priv/sql/Dispatch \
	priv/sql/GetQueue \
	priv/sql/GetJobs \
	priv/sql/GetJobsJSON \
	priv/sql/GetJobJSON

priv/sql/%: priv/sql/%.sql
	psql -h alexs-macbook-pro.local csvus < $<



all: deps
	@./rebar compile

deps:
	@./rebar get-deps

clean:
	@./rebar clean

distclean: clean
	@./rebar delete-deps

docs:
	@erl -noshell -run edoc_run application '$(APP)' '"."' '[]'
