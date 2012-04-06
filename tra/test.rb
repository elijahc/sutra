#!/usr/bin/env ruby

require 'rubygems'

require 'awesome_print'
require 'httparty'

require 'minitest/spec'
require 'minitest/autorun'

require 'sqlite3'

class TRA
	include HTTParty

	base_uri 'http://localhost:4567'
	format :json

	def create_project( name, metadata = {} )

		input_data = { 'name' => name }
		input_data.merge! metadata

		process_result( post( '/projects/create', { :body => input_data } ) )
	end

	def update_project( id, data )

	end

	def delete_project( id )

	end

	def get_project( id )

	end

	def create_run( project_id, description, submitted_by, metadata = {} )

	end

	def update_run( run_id, data )

	end

	def delete_run( run_id )

	end

	def get_run( run_id )

	end

	def create_result( run_id, test_case, status, metadata = {} )

	end

	def update_result( result_id, data )

	end

	def delete_result( result_id )

	end

	def get_result( result_id )

	end
end

class TRATests < MiniTest::Unit::TestCase

	def setup
		@host     = 'localhost'
		@port     = 4567
		@base_url = '/'

		# TODO: HTTP POST : /clear to reset database to empty.
	end

	def this_method
		caller[0]=~/`(.*?)'/
		$1
	end

	def test_create_project
		result = TRA.create_project( this_method )

	end

	def test_create_incomplete_project
	end

	def test_create_duplicate_project
	end

	def test_update_existing_project
	end

	def test_update_nonexistant_project
	end

	def test_delete_existing_project
	end

	def test_delete_nonexistant_project
	end

	def test_list_projects_when_empty
	end

	def test_list_projects
	end

	def test_create_run
	end

	def test_create_run_nonexistant_project
	end

	def test_create_incomplete_run
	end

	def test_create_duplicate_run
	end

	def test_update_existing_run
	end

	def test_update_nonexistant_run
	end

	def test_delete_existing_run
	end

	def test_delete_nonexistant_run
	end

	def test_list_runs
	end

	def test_list_project_runs
	end

	def test_list_project_runs_when_empty
	end

	def test_create_result
	end

	def test_create_result_nonexistant_run
	end

	def test_create_incomplete_result
	end

	def test_create_duplicate_result
	end

	def test_update_existing_result
	end

	def test_update_nonexistant_result
	end

	def test_delete_existing_result
	end

	def test_delete_nonexistant_result
	end

	def test_list_results
	end

	def test_list_run_results
	end

	def test_list_run_results_when_empty
	end

end