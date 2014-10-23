RSpec.shared_examples :container do
  let(:time_matching) { a_string_matching(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{10}Z$/) }
  let(:id_matching) { a_string_matching(/^[0-9a-f]{64}$/) }
  let(:query) do
    { 'name' => 'my_container' }
  end
  let(:options) do
    {
      body: {
        'Image' => 'ubuntu:trusty',
        'Hostname' => 'container-host',
        'PortSpecs' => ['22', '23/udp'],
        'Cmd' => ['/bin/echo', 'the echo sentence']
      }
    }
  end
  let(:create_container) do
    -> { subject.perform(:post, '/containers/create', query, options) }
  end

  let(:start_options) do
    {
      body: {
        'PortBindings' => {
          '22/tcp' => [
            { 'HostPort' => '11022' },
            { 'HostPort' => '11023' }
          ]
        },
        'Binds' => ['/data_on_host:/data_inside_container/mounted']
      }
    }
  end
  let(:start_container) do
    ->(id) { subject.perform(:post, "/containers/#{id}/start", 'a_query', start_options) }
  end
  let(:stop_container) do
    ->(id) { subject.perform(:post, "/containers/#{id}/stop", 'a_query', body: {}) }
  end
  let(:kill_container) do
    ->(id) { subject.perform(:post, "/containers/#{id}/kill", 'a_query', body: {}) }
  end
  let(:pause_container) do
    ->(id) { subject.perform(:post, "/containers/#{id}/pause", 'a_query', 'an_options') }
  end
  let(:unpause_container) do
    ->(id) { subject.perform(:post, "/containers/#{id}/unpause", 'a_query', 'an_options') }
  end
  let(:container_details) do
    ->(id) { subject.perform(:get, "/containers/#{id}/json", 'a_query', 'an_option') }
  end
  let(:all_containers) do
    -> { subject.perform(:get, '/containers/json', 'a_query', 'an_options') }
  end
  let(:remove_container) do
    ->(id) { subject.perform(:delete, "/containers/#{id}", 'a_query', 'an_option') }
  end

  let!(:id) { create_container.call['Id'] }
  let!(:container) { subject.send(:containers)[id[0..12]] }
end
