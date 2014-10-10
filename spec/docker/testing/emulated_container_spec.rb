require 'spec_helper'

module Docker::Testing
  describe EmulatedContainer do
    let(:id) { 'edbf3d10be15c0b12db2205949843447805ca4eb1bb9535b9547c9cc7edde368' }
    let(:query) do
      { 'name' => 'my_container' }
    end
    let(:options) do
      {
        body: {
          'Image' => 'ubuntu:trusty',
          'Hostname' => 'container-host',
          'Cmd' => ['/bin/echo', 'the echo sentence']
        }
      }
    end

    subject { EmulatedContainer.new(id, query, options) }

    it 'includes the template' do
      expect(subject).to respond_to(:new_template)
    end

    describe '#initialize' do
      it 'initializes a new container' do
        expect(subject.template)
          .to include('id' => 'edbf3d10be15c0b12db2205949843447805ca4eb1bb9535b9547c9cc7edde368',
                      'Name' => '/my_container',
                      'Path' => '/bin/echo',
                      'Args' => ['the echo sentence'])
      end
    end

    describe '#user' do
      it 'returns the user name' do
        expect(subject.user).to eq('root')
      end
    end

    describe '#pid' do
      it 'returns the container pid' do
        expect(subject.pid).to eq(subject.template['State']['Pid'])
      end
    end

    describe '#ppid' do
      it 'returns the container parent pid' do
        expect(subject.ppid).to be_an_instance_of(Fixnum)
      end

      it 'does not change for the same container' do
        expect { subject.ppid }.to_not change { subject.ppid }
      end
    end

    describe '#tty_name' do
      context 'when tty options is true' do
        let(:tty_opts) do
          options.deep_merge(body: { 'Tty' => true })
        end
        let(:tty_subject) { EmulatedContainer.new(id, query, tty_opts) }

        it 'returns the tty name' do
          expect(tty_subject.tty_name).to eq('pts/6')
        end
      end

      context 'when tty options is false' do
        let(:tty_opts) do
          options.deep_merge(body: { 'Tty' => false })
        end
        let(:tty_subject) { EmulatedContainer.new(id, query, tty_opts) }

        it 'returns the tty name' do
          expect(tty_subject.tty_name).to eq('?')
        end
      end
    end

    describe '#define_pid' do
      it 'defines a new pid value' do
        expect { subject.define_pid }.to change { subject.pid }
      end
    end

    describe '#command' do
      it 'returns the command passed at container create time' do
        expect(subject.command).to eq("/bin/echo 'the echo sentence'")
      end
    end

    describe '#state' do
      it 'does not update state if argument is nil' do
        expect { subject.state(nil) }.to_not change { subject.template['State'] }
      end

      it 'updates the container state if argument not nil' do
        expect { subject.state('ExitCode' => -999) }
          .to change { subject.template['State']['ExitCode'] }
          .from(0).to(-999)
      end
    end

    describe '#host_config' do
      it 'does not update host config if argument is nil' do
        expect { subject.host_config(nil) }.to_not change { subject.template['HostConfig'] }
      end

      it 'updates the host config if argument not nil' do
        expect { subject.host_config('Privileged' => true) }
          .to change { subject.template['HostConfig']['Privileged'] }
          .from(false).to(true)
      end
    end

    describe '#inspect' do
      it 'returns container inspection' do
        expect(subject.inspect).to include('#<Docker::Testing::EmulatedContainer:0x')
      end
    end

    describe '#define_pulic_ports' do
      context 'when the start command receive no ports binding' do
        it 'does nothing' do
          expect(subject.define_pulic_ports).to eq(nil)
          expect { subject.define_pulic_ports }
            .to_not change { subject.template['HostConfig']['PortBindings'] }
          expect { subject.define_pulic_ports }
            .to_not change { subject.template['NetworkSettings']['Ports'] }
        end
      end

      context 'when the start command receives ports binding' do
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
        let(:binding_options) do
          {
            '22/tcp' => [
              { 'HostPort' => '11022' },
              { 'HostPort' => '11023' }
            ]
          }
        end

        subject { EmulatedContainer.new(id, query, options) }

        it 'formats port bindings with exposed ports' do
          expect { subject.define_pulic_ports(binding_options) }
            .to change { subject.template['HostConfig']['PortBindings'] }
            .from(nil)
            .to('22/tcp' => [
              { 'HostPort' => '11022', 'HostIp' => '0.0.0.0' },
              { 'HostPort' => '11023', 'HostIp' => '0.0.0.0' }
            ],
                '23/udp' => nil)
        end

        it 'updates network ports with port bindings' do
          expect { subject.define_pulic_ports(binding_options) }
            .to change { subject.template['NetworkSettings']['Ports'] }
            .from('22/tcp' => nil, '23/udp' => nil)
            .to('22/tcp' => [
              { 'HostPort' => '11022', 'HostIp' => '0.0.0.0' },
              { 'HostPort' => '11023', 'HostIp' => '0.0.0.0' }
            ],
                '23/udp' => nil)
        end
      end

      describe '#ports_details' do
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
        let(:binding_options) do
          {
            '22/tcp' => [
              { 'HostPort' => '11022' },
              { 'HostPort' => '11023' }
            ]
          }
        end

        subject do
          EmulatedContainer.new(id, query, options).tap do |container|
            container.define_pulic_ports(binding_options)
          end
        end

        it 'returns well formated ports informations' do
          expect(subject.ports_details)
            .to eq([{ 'IP' => '0.0.0.0', 'PrivatePort' => '22',
                      'PublicPort' => '11022', 'Type' => 'tcp' },
                    { 'IP' => '0.0.0.0', 'PrivatePort' => '22',
                      'PublicPort' => '11023', 'Type' => 'tcp' },
                    { 'PrivatePort' => '23', 'Type' => 'udp' }])
        end
      end
    end
  end
end
