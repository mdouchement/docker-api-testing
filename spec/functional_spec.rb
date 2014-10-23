require 'spec_helper'

module Docker
  describe 'functional tests' do
    before do
      Testing.fake!
    end

    let(:options) do
      {
        'Cmd' => '/bin/bash',
        'Image' => 'ubuntu:trusty'
      }
    end
    let(:create_conn) do
      -> { Connection.new('http://localhost', port: 4243) }
    end
    let(:conn) { create_conn.call }
    let!(:container) { Container.create(options, conn) }
    let(:cid) { container.id }
    let(:short_cid) { cid[0..12] }

    it 'creates a connection' do
      expect(create_conn.call).to be_an_instance_of(Connection)
    end

    it 'creates a container' do
      expect(Container.create(options))
        .to be_an_instance_of(Container)
    end

    it 'creates a container for a specific connection' do
      expect(container.connection)
        .to eq(conn)
    end

    it 'starts a container' do
      expect { container.start }
        .to change {
          conn.send(:container_manager)
              .send(:containers)[short_cid]
              .template['State']['Running']
        }.from(false).to(true)
    end
  end
end
