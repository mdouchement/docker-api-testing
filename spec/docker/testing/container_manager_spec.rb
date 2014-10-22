require 'spec_helper'

module Docker::Testing
  describe ContainerManager do
    include_examples :container

    # `#perform' dispatcher tested with below methods

    describe '#post_create' do
      it 'creates a new container' do
        expect { create_container.call }
        .to change { subject.send(:containers).size }.by(1)
      end

      it 'returns a response' do
        expect(create_container.call)
          .to include('Id' => id_matching, 'Warnings' => nil)
      end
    end

    describe '#post_start_with_id' do
      before do
        # Allow `ordered' clause for multiple it
        allow(container).to receive(:state)
      end

      context 'when have been stopped' do
        before do
          start_container.call(id)
          stop_container.call(id)
        end

        it 'restores container' do
          expect { start_container.call(id) }
            .to change { subject.send(:stoped_containers).size }.by(-1)
            .and change { subject.send(:containers).size }.by(1)
        end

        it 're-initializes finished at timestamp' do
          expect(container).to receive(:state)
            .with('FinishedAt' => '0001-01-01T00:00:00Z').ordered

          start_container.call(id)
        end

        it 'defines a PID' do
          expect(container).to receive(:define_pid)

          start_container.call(id)
        end
      end

      it 'defines public ports' do
        expect(container).to receive(:define_pulic_ports)
          .with(start_options[:body]['PortBindings'])

        start_container.call(id)
      end

      it 'defines host configuration' do
        expect(container).to receive(:host_config)
          .with('Binds' => start_options[:body]['Binds'])

        start_container.call(id)
      end

      it 'changes state' do
        expect(container).to receive(:state)
          .with('StartedAt' => time_matching, 'Running' => true).ordered

        start_container.call(id)
      end

      it 'defines a PID' do
        expect(container).to receive(:define_pid)

        start_container.call(id)
      end

      it 'returns a response' do
        expect(start_container.call(id))
          .to include('Id' => id[0..12], 'Warnings' => nil)
      end
    end

    describe '#post_stop_with_id' do
      before do
        start_container.call(id)
      end

      context 'when container is already stoped' do
        it 'returns the default response' do
          stop_container.call(id)

          expect(stop_container.call(id))
            .to include('Id' => id[0..12], 'Warnings' => nil)
        end
      end

      it 'updates host configuration' do
        expect(container).to receive(:host_config).with({})
        stop_container.call(id)
      end

      it 'define finished at timestamp' do
        expect(container).to receive(:state)
          .with('FinishedAt' => time_matching, 'Running' => false)

        stop_container.call(id)
      end

      it 'removes the containers' do
        expect { stop_container.call(id) }
          .to change { subject.send(:stoped_containers).size }.by(1)
          .and change { subject.send(:containers).size }.by(-1)
      end

      it 'returns a response' do
        expect(stop_container.call(id))
          .to include('Id' => id[0..12], 'Warnings' => nil)
      end
    end

    describe '#post_restart_with_id' do
      before  do
        start_container.call(id)
      end

      it 'restarts the container' do
        expect(subject).to receive(:post_stop_with_id)
          .with(id[0..12], 'a_query', body: {})
          .and_call_original
          .ordered
        expect(subject).to receive(:post_start_with_id)
          .with(id[0..12], 'a_query', body: {})
          .and_call_original
          .ordered

        subject.perform(:post, "/containers/#{id}/restart", 'a_query', options)
      end

      context 'when the container does not exists' do
        it 'raises an error' do
          expect { subject.perform(:post, '/containers/unknown_id/restart', 'a_query', options) }
            .to raise_error(Docker::Error::NotFoundError,
                            'Expected(200..204) <=> Actual(404 Not Found)')
        end
      end
    end

    describe '#get_top_with_id' do
      let(:strftime) { '18:01' }
      let(:response) do
        {
          'Titles' => %w(UID PID PPID C STIME TTY TIME CMD),
          'Processes' => [['root', container.pid, container.ppid, '0',
                           strftime, '?', '00:00:00',
                           "/bin/echo 'the echo sentence'"]]
        }
      end

      before  do
        allow_any_instance_of(Time).to receive(:strftime).and_return(strftime)
        start_container.call(id)
      end

      it 'returns a response' do
        expect(subject.perform(:get, "/containers/#{id}/top", 'a_query', options))
          .to eq(response)
      end
    end

    describe '#post_pause_with_id' do
      it 'updates container state' do
        expect(container).to receive(:state).with('Paused' => true)
        pause_container.call(id)
      end

      it 'returns a response' do
        expect(pause_container.call(id)).to eq('Id' => id[0..12], 'Warnings' => nil)
      end
    end

    describe '#post_unpause_with_id' do
      it 'modifies container state' do
        expect(container).to receive(:state).with('Paused' => false)
        unpause_container.call(id)
      end

      it 'returns a response' do
        expect(unpause_container.call(id)).to eq('Id' => id[0..12], 'Warnings' => nil)
      end
    end

    describe '#post_kill_with_id' do
      it 'updates host configuration' do
        expect(container).to receive(:host_config).with({})
        kill_container.call(id)
      end

      it 'updates container state' do
        expect(container).to receive(:state)
          .with('ExitCode' => -1, 'FinishedAt' => time_matching, 'Running' => false)

        kill_container.call(id)
      end

      it 'removes the containers' do
        expect { kill_container.call(id) }
         .to change { subject.send(:stoped_containers).size }.by(1)
         .and change { subject.send(:containers).size }.by(-1)
      end

      it 'returns a response' do
        expect(kill_container.call(id)).to eq('Id' => id[0..12], 'Warnings' => nil)
      end
    end

    describe '#get_json_with_id' do
      context 'when container is running' do
        before do
          start_container.call(id)
        end

        it 'returns container details' do
          expect(container_details.call(id)).to eq(container.template)
        end
      end

      context 'when container is stoped' do
        before do
          start_container.call(id)
          stop_container.call(id)
        end

        it 'returns container details' do
          expect(container_details.call(id)).to eq(container.template)
        end
      end

      context 'when there is no container' do
        it 'raises an error' do
          expect { container_details.call('unknown_id') }
            .to raise_error(Docker::Error::NotFoundError,
                            'Expected([200, 201, 202, 203, 204, 304]) <=> Actual(404 Not Found)')
        end
      end
    end

    describe '#get_json' do
      let(:response) do
        [
          { 'Command' => "/bin/echo 'the echo sentence'",
            'Created' => Time.parse(container.template['Created']).to_i,
            'Id' => id,
            'Image' => 'ba5877dc9beca5a0af9521846e79419e98575a11cbfe1ff2ad2e95302cff26bf',
            'Names' => ['/my_container'],
            'Ports' => [
              {
                'IP' => '0.0.0.0',
                'PrivatePort' => '22',
                'PublicPort' => '11022',
                'Type' => 'tcp'
              },
              {
                'IP' => '0.0.0.0',
                'PrivatePort' => '22',
                'PublicPort' => '11023',
                'Type' => 'tcp'
              },
              {
                'PrivatePort' => '23',
                'Type' => 'udp'
              }
            ],
            'Status' => 'Up Less than a second'
          }
        ]
      end

      before do
        start_container.call(id)
      end

      it 'returns all containers' do
        expect(all_containers.call).to eq(response)
      end
    end

    describe '#get_wait_with_id' do
      it 'returns a status code' do
        expect(subject.perform(:get, '/containers/5453685454/wait', query, options))
          .to eq('StatusCode' => 0)
      end
    end

    %w(logs changes copy export attach).each do |action|
      describe "#get_#{ action }_with_id" do
        it 'raises an error' do
          expect { subject.perform(:get, "/containers/5453685454/#{ action }", query, options) }
            .to raise_error(RuntimeError, 'Unsupported')
        end
      end
    end

    describe '#delete' do
      context 'when container is running' do
        before do
          start_container.call(id)
        end

        it 'raise an error' do
          expect { remove_container.call(id) }
            .to raise_error(Excon::Errors::NotAcceptable,
                            'Expected(200..204) <=> Actual(406 Not Acceptable)')
        end
      end

      context 'when there is no container' do
        it 'raises an error' do
          expect { remove_container.call('unknown_id') }
            .to raise_error(Docker::Error::NotFoundError,
                            'Expected(200..204) <=> Actual(404 Not Found)')
        end
      end

      context 'when container is stoped' do
        before do
          start_container.call(id)
          stop_container.call(id)
        end

        it 'removes the container' do
          expect { remove_container.call(id) }
            .to change { subject.send(:stoped_containers).size }.by(-1)
        end

        it 'returns nil' do
          expect(remove_container.call(id)).to eq(nil)
        end
      end
    end
  end
end
